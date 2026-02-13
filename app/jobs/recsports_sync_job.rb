class RecsportsSyncJob < ApplicationJob
  queue_as :default

  def perform(manual_payload: nil)
    credential = RecsportsCredential.first
    return unless credential

    rows = if credential.manual_upload?
      parse_manual_payload(manual_payload)
    else
      Recsports::Client.new(credential).fetch_attendance
    end

    Recsports::Importer.new(rows: rows).call
    credential.update!(last_checked_at: Time.current, last_error: nil, active: true)
  rescue StandardError => e
    credential&.update(last_error: e.message, active: false)
    raise
  end

  private

  def parse_manual_payload(payload)
    return [] if payload.blank?

    JSON.parse(payload)
  rescue JSON::ParserError
    []
  end
end
