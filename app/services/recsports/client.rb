require "json"
require "net/http"
require "nokogiri"
require "set"
require "uri"

module Recsports
  class Client
    LOGIN_FIELD_NAMES = %w[email username user login netid].freeze
    PASSWORD_FIELD_NAMES = %w[password pass pwd].freeze

    def initialize(credential)
      @credential = credential
      @cookies = {}
    end

    def test_access!
      fetch_snapshot
      true
    end

    def fetch_snapshot
      response = authenticated_response(@credential.form_url)
      event_index_response = ensure_event_index(response)
      event_urls = extract_event_urls(event_index_response[:body], event_index_response[:url])

      raise "No event detail links were found on the configured page." if event_urls.empty?

      events = event_urls.map do |event_url|
        event_response = get(event_url, referer: event_index_response[:url])
        parse_event_page(event_response[:body], event_response[:url])
      end.compact

      raise "No participant tables were found across the discovered events." if events.empty?

      { "events" => events }
    end

    private

    def authenticated_response(url)
      response = get(url)
      login_form = extract_login_form(response[:body], response[:url])
      return response unless login_form

      raise "RecSports username/password are required for this page." if @credential.username.blank? || @credential.password.blank?

      submit_form(login_form, username: @credential.username, password: @credential.password, referer: response[:url])
    end

    def ensure_event_index(response)
      event_urls = extract_event_urls(response[:body], response[:url])
      return response if event_urls.any?

      doc = html_doc(response[:body])
      home_events_link = doc.css("a").find { |link| link.text.to_s.squish.casecmp("Home Events").zero? }
      return response unless home_events_link

      href = absolute_url(home_events_link["href"], response[:url])
      return response if href.blank? || href == response[:url]

      get(href, referer: response[:url])
    end

    def extract_event_urls(body, base_url)
      doc = html_doc(body)

      doc.css("a").filter_map do |link|
        next unless link.text.to_s.squish.casecmp("View").zero?

        absolute_url(link["href"], base_url)
      end.uniq
    end

    def parse_event_page(body, source_url)
      doc = html_doc(body)
      table = participants_table(doc)
      return if table.nil?

      page_text = doc.text.to_s.gsub("\u00a0", " ").squish
      starts_at, ends_at = parse_datetime_range(labeled_value(page_text, "Event Date/Time", "Created By", "Created At", "Participants"))
      created_by_value = labeled_value(page_text, "Created By", "Created At", "Participants")
      created_by_name, created_by_email = parse_created_by(created_by_value)

      {
        "title" => labeled_value(page_text, "Event Name", "Event Type", "Event Venue", "Event Date/Time").presence || doc.at_css("h1, h2, h3")&.text.to_s.squish,
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

    def parse_participants(table)
      headers = table.css("thead th").map { |header| header.text.to_s.squish.downcase }
      first_name_index = header_index(headers, "first name")
      last_name_index = header_index(headers, "last name")
      uin_index = header_index(headers, "uin")

      table.css("tbody tr").filter_map.with_index do |row, position|
        cells = row.css("td").map { |cell| cell.text.to_s.squish }
        next if cells.empty?

        first_name = cell_value(cells, first_name_index, fallback: 0)
        last_name = cell_value(cells, last_name_index, fallback: 1)
        uin = cell_value(cells, uin_index, fallback: 2)
        next if [first_name, last_name, uin].all?(&:blank?)

        {
          "first_name" => first_name,
          "last_name" => last_name,
          "uin" => uin,
          "position" => position
        }
      end
    end

    def participants_table(doc)
      doc.css("table").find do |table|
        headers = table.css("thead th").map { |header| header.text.to_s.squish.downcase }
        headers.include?("first name") && headers.include?("last name")
      end
    end

    def header_index(headers, expected)
      headers.index(expected)
    end

    def cell_value(cells, index, fallback:)
      value = index ? cells[index] : cells[fallback]
      value.to_s.squish.presence
    end

    def extract_login_form(body, base_url)
      doc = html_doc(body)
      form = doc.css("form").find { |candidate| password_input(candidate).present? }
      return if form.nil?

      {
        action: absolute_url(form["action"], base_url) || base_url,
        method: form["method"].to_s.downcase.presence || "post",
        fields: form.css("input, textarea, select").map do |field|
          {
            name: field["name"],
            value: field["value"],
            type: field.name == "select" ? "select" : field["type"].to_s.downcase
          }
        end
      }
    end

    def password_input(form)
      form.css("input").find do |input|
        type = input["type"].to_s.downcase
        name = input["name"].to_s.downcase
        type == "password" || PASSWORD_FIELD_NAMES.any? { |candidate| name.include?(candidate) }
      end
    end

    def submit_form(form, username:, password:, referer:)
      payload = {}

      form[:fields].each do |field|
        next if field[:name].blank?
        next if field[:type] == "submit"

        payload[field[:name]] = field[:value].to_s
      end

      username_key = payload.keys.find { |key| LOGIN_FIELD_NAMES.any? { |candidate| key.to_s.downcase.include?(candidate) } }
      password_key = payload.keys.find { |key| PASSWORD_FIELD_NAMES.any? { |candidate| key.to_s.downcase.include?(candidate) } }

      raise "Could not identify the login form fields on the configured page." if username_key.blank? || password_key.blank?

      payload[username_key] = username
      payload[password_key] = password

      request(form[:method], form[:action], form_data: payload, referer: referer)
    end

    def get(url, referer: nil)
      request(:get, url, referer: referer)
    end

    def request(method, url, form_data: nil, referer: nil, redirects: 5)
      raise "Too many redirects while contacting RecSports." if redirects.negative?

      uri = URI.parse(url)
      request_class = method.to_s.casecmp("post").zero? ? Net::HTTP::Post : Net::HTTP::Get
      http_request = request_class.new(uri)
      http_request["Cookie"] = cookie_header if @cookies.any?
      http_request["Referer"] = referer if referer.present?
      http_request["User-Agent"] = "DozenUltimateAttendanceTracker/1.0"

      if form_data.present?
        http_request.set_form_data(form_data)
      end

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(http_request)
      end

      store_cookies(response)

      case response
      when Net::HTTPRedirection
        location = absolute_url(response["location"], url)
        request(:get, location, referer: url, redirects: redirects - 1)
      when Net::HTTPSuccess
        { body: response.body.to_s, url: url, code: response.code.to_i }
      else
        raise "RecSports request failed (HTTP #{response.code})"
      end
    end

    def store_cookies(response)
      Array(response.get_fields("Set-Cookie")).each do |cookie|
        pair = cookie.to_s.split(";").first
        key, value = pair.split("=", 2)
        next if key.blank?

        @cookies[key] = value.to_s
      end
    end

    def cookie_header
      @cookies.map { |key, value| "#{key}=#{value}" }.join("; ")
    end

    def html_doc(body)
      Nokogiri::HTML(body.to_s)
    end

    def absolute_url(raw_url, base_url)
      return if raw_url.blank?

      URI.join(base_url, raw_url).to_s
    rescue URI::InvalidURIError
      raw_url
    end

    def labeled_value(text, label, *terminators)
      return if text.blank?

      escaped_terminators = terminators.flatten.compact.map { |value| Regexp.escape("#{value}:") }
      boundary = escaped_terminators.any? ? "(?=#{escaped_terminators.join('|')}|$)" : "$"
      match = text.match(/#{Regexp.escape(label)}:\s*(.*?)\s*#{boundary}/i)
      match && match[1].to_s.squish.presence
    end

    def parse_datetime_range(value)
      return [nil, nil] if value.blank?

      start_text, end_text = value.split(/\s+to\s+/i, 2)
      [parse_time(start_text), parse_time(end_text)]
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_created_by(value)
      return [nil, nil] if value.blank?

      email = value[/\(([^)]+)\)/, 1]
      name = value.sub(/\s*\([^)]+\)\s*/, "").squish
      [name.presence, email.presence]
    end

    def extract_external_id(url)
      uri = URI.parse(url)
      query = URI.decode_www_form(uri.query.to_s).to_h
      query["id"].presence || query["eventId"].presence || uri.path.split("/").last.presence
    rescue URI::InvalidURIError
      nil
    end
  end
end
