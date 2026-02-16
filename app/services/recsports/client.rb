require "net/http"
require "json"
require "csv"

module Recsports
  class Client
    def initialize(credential)
      @credential = credential
    end

    def test_access!
      response = get(@credential.form_url)
      raise "RecSports access failed (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

      true
    end

    def fetch_attendance
      response = get(@credential.form_url)
      raise "RecSports access failed (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

      parse_rows(response.body)
    end

    private

    def get(url)
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      if @credential.username.present?
        request.basic_auth(@credential.username, @credential.password.to_s)
      end

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    end

    def parse_rows(body)
      parsed = JSON.parse(body)
      parsed.is_a?(Array) ? parsed : parsed.fetch("records", [])
    rescue JSON::ParserError
      CSV.parse(body, headers: true).map(&:to_h)
    end
  end
end
