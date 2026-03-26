#!/usr/bin/env ruby

require "json"
require "net/http"
require "nokogiri"
require "selenium-webdriver"
require "time"
require "uri"

class BrowserSync
  DEFAULT_APP_URL = "http://localhost:3000".freeze
  DEFAULT_START_URL = "https://sportclubs.tamu.edu/home/userClubs".freeze

  def initialize
    @app_url = ENV.fetch("APP_URL", DEFAULT_APP_URL)
    @start_url = ENV.fetch("RECSPORTS_START_URL", DEFAULT_START_URL)
    @token = ENV["RECSPORTS_BROWSER_TOKEN"].to_s.strip
    raise "RECSPORTS_BROWSER_TOKEN is required." if @token.empty?
  end

  def run
    driver = build_driver
    driver.navigate.to(@start_url)

    puts "A Chrome window has opened."
    puts "Complete the Microsoft login and Duo prompt there."
    puts "Once you are back on the Sport Clubs Home Events page, press Enter here to continue."
    $stdin.gets

    snapshot = scrape_snapshot(driver)
    upload_snapshot(snapshot)
    puts "Browser-assisted RecSports sync completed."
  ensure
    driver&.quit
  end

  private

  def build_driver
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--start-maximized")
    Selenium::WebDriver.for(:chrome, options: options)
  end

  def scrape_snapshot(driver)
    event_urls = extract_event_urls(driver.page_source, driver.current_url)
    raise "No event detail links were found on the current page." if event_urls.empty?

    events = event_urls.map do |event_url|
      driver.navigate.to(event_url)
      sleep 1
      parse_event_page(driver.page_source, driver.current_url)
    end.compact

    raise "No participant tables were found across the discovered event pages." if events.empty?

    { "events" => events }
  end

  def extract_event_urls(body, base_url)
    doc = Nokogiri::HTML(body.to_s)
    doc.css("a").filter_map do |link|
      next unless link.text.to_s.strip.casecmp("View").zero?

      absolute_url(link["href"], base_url)
    end.uniq
  end

  def parse_event_page(body, source_url)
    doc = Nokogiri::HTML(body.to_s)
    table = participants_table(doc)
    return if table.nil?

    page_text = doc.text.to_s.gsub("\u00a0", " ").gsub(/\s+/, " ").strip
    starts_at, ends_at = parse_datetime_range(labeled_value(page_text, "Event Date/Time", "Created By", "Created At", "Participants"))
    created_by_value = labeled_value(page_text, "Created By", "Created At", "Participants")
    created_by_name, created_by_email = parse_created_by(created_by_value)

    {
      "title" => labeled_value(page_text, "Event Name", "Event Type", "Event Venue", "Event Date/Time") || doc.at_css("h1, h2, h3")&.text.to_s.strip,
      "event_type" => labeled_value(page_text, "Event Type", "Event Venue", "Event Date/Time", "Created By"),
      "venue" => labeled_value(page_text, "Event Venue", "Event Date/Time", "Created By", "Created At"),
      "starts_at" => starts_at,
      "ends_at" => ends_at,
      "source_url" => source_url,
      "external_id" => extract_external_id(source_url),
      "created_by_name" => created_by_name,
      "created_by_email" => created_by_email,
      "source_created_at" => parse_time(labeled_value(page_text, "Created At", "Participants")),
      "participants" => parse_participants(table)
    }
  end

  def participants_table(doc)
    doc.css("table").find do |table|
      headers = table.css("thead th").map { |header| header.text.to_s.strip.downcase }
      headers.include?("first name") && headers.include?("last name")
    end
  end

  def parse_participants(table)
    headers = table.css("thead th").map { |header| header.text.to_s.strip.downcase }
    first_name_index = headers.index("first name")
    last_name_index = headers.index("last name")
    uin_index = headers.index("uin")

    table.css("tbody tr").filter_map.with_index do |row, position|
      cells = row.css("td").map { |cell| cell.text.to_s.gsub(/\s+/, " ").strip }
      next if cells.empty?

      first_name = pick_cell(cells, first_name_index, 0)
      last_name = pick_cell(cells, last_name_index, 1)
      uin = pick_cell(cells, uin_index, 2)
      next if [first_name, last_name, uin].all? { |value| value.nil? || value.empty? }

      {
        "first_name" => first_name,
        "last_name" => last_name,
        "uin" => uin,
        "position" => position
      }
    end
  end

  def pick_cell(cells, header_index, fallback_index)
    value = header_index ? cells[header_index] : cells[fallback_index]
    value.to_s.strip.empty? ? nil : value.to_s.strip
  end

  def labeled_value(text, label, *terminators)
    escaped_terminators = terminators.flatten.compact.map { |value| Regexp.escape("#{value}:") }
    boundary = escaped_terminators.any? ? "(?=#{escaped_terminators.join('|')}|$)" : "$"
    match = text.match(/#{Regexp.escape(label)}:\s*(.*?)\s*#{boundary}/i)
    match && match[1].to_s.strip
  end

  def parse_datetime_range(value)
    return [nil, nil] if value.nil? || value.empty?

    start_text, end_text = value.split(/\s+to\s+/i, 2)
    [parse_time(start_text), parse_time(end_text)]
  end

  def parse_created_by(value)
    return [nil, nil] if value.nil? || value.empty?

    email = value[/\(([^)]+)\)/, 1]
    name = value.sub(/\s*\([^)]+\)\s*/, "").strip
    [blank_to_nil(name), blank_to_nil(email)]
  end

  def parse_time(value)
    return nil if value.nil? || value.empty?

    Time.parse(value).iso8601
  rescue ArgumentError
    nil
  end

  def extract_external_id(url)
    uri = URI.parse(url)
    query = URI.decode_www_form(uri.query.to_s).to_h
    blank_to_nil(query["id"]) || blank_to_nil(query["eventId"]) || blank_to_nil(uri.path.split("/").last)
  rescue URI::InvalidURIError
    nil
  end

  def absolute_url(raw_url, base_url)
    return nil if raw_url.nil? || raw_url.empty?

    URI.join(base_url, raw_url).to_s
  rescue URI::InvalidURIError
    raw_url
  end

  def blank_to_nil(value)
    stripped = value.to_s.strip
    stripped.empty? ? nil : stripped
  end

  def upload_snapshot(snapshot)
    uri = URI.parse("#{@app_url}/admin/recsports/browser_sync")
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      "token" => @token,
      "snapshot" => JSON.generate(snapshot)
    )

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    return if response.is_a?(Net::HTTPSuccess)

    raise "Upload failed (HTTP #{response.code}): #{response.body}"
  end
end

BrowserSync.new.run
