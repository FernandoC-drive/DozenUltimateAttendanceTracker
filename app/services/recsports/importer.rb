require "digest"
require "securerandom"

module Recsports
  class Importer
    def initialize(snapshot:)
      @snapshot = snapshot
    end

    def call
      events = normalized_events
      return if events.empty?

      synced_at = Time.current
      affected_dates = []

      ActiveRecord::Base.transaction do
        events.each do |event_payload|
          existing_event = RecsportsEvent.find_by(source_url: event_payload["source_url"])
          affected_dates << existing_event.event_date if existing_event&.event_date.present?

          event = upsert_event(event_payload, synced_at)
          affected_dates << event.event_date if event.event_date.present?

          event.participants.destroy_all

          deduplicated_participants(event_payload.fetch("participants", [])).each do |participant_payload|
            user = resolve_user(participant_payload)

            event.participants.create!(
                 user: user,
                 first_name: participant_payload["first_name"].to_s.strip,
                 last_name: participant_payload["last_name"].to_s.strip,
                 recsports_uin: participant_payload["uin"].to_s.strip.presence,
                 position: participant_payload["position"].to_i
            )
          end
        end

        replace_attendance_rows!(affected_dates.compact.uniq)
      end
    end

    private

    def normalized_events
      payload = @snapshot.is_a?(Hash) ? @snapshot : {}
      events = payload["events"] || payload[:events]
      return Array(events).filter_map { |event| normalize_event(event) } if events.present?

      legacy_rows = Array(@snapshot)
      return [] if legacy_rows.empty?

      grouped_rows = legacy_rows.group_by { |row| [parse_date(row["date"] || row[:date]), row["event_name"] || row[:event_name] || "Imported Event"] }
      grouped_rows.map do |(date, title), rows|
        next if date.nil?

        {
             "title" => title,
             "starts_at" => date.in_time_zone,
             "ends_at" => date.in_time_zone,
             "source_url" => "manual://#{date}-#{title.parameterize}",
             "participants" => rows.map.with_index do |row, index|
            {
                 "first_name" => row["first_name"] || row[:first_name] || row["name"] || row[:name],
                 "last_name" => row["last_name"] || row[:last_name],
                 "uin" => row["uin"] || row[:uin],
                 "position" => index
            }
             end
        }
      end.compact
    end

    def normalize_event(event)
      payload = event.respond_to?(:stringify_keys) ? event.stringify_keys : event.to_h.transform_keys(&:to_s)
      participants = Array(payload["participants"]).filter_map do |participant|
        normalized = participant.respond_to?(:stringify_keys) ? participant.stringify_keys : participant.to_h.transform_keys(&:to_s)
        first_name = normalized["first_name"].to_s.strip
        last_name = normalized["last_name"].to_s.strip
        next if first_name.blank? && last_name.blank?

        {
             "first_name" => first_name,
             "last_name" => last_name,
             "uin" => normalized["uin"].to_s.strip.presence,
             "position" => normalized["position"].to_i
        }
      end

      return if participants.empty?

      {
           "title" => payload["title"].presence || "Imported Event",
           "event_type" => payload["event_type"].presence,
           "venue" => payload["venue"].presence,
           "starts_at" => parse_time(payload["starts_at"]),
           "ends_at" => parse_time(payload["ends_at"]),
           "source_url" => payload["source_url"].presence || "manual://#{SecureRandom.hex(8)}",
           "external_id" => payload["external_id"].presence,
           "created_by_name" => payload["created_by_name"].presence,
           "created_by_email" => payload["created_by_email"].presence,
           "source_created_at" => parse_time(payload["source_created_at"]),
           "participants" => deduplicated_participants(participants)
      }
    end

    def upsert_event(payload, synced_at)
      event = RecsportsEvent.find_or_initialize_by(source_url: payload["source_url"])
      event.assign_attributes(
           title: payload["title"],
           event_type: payload["event_type"],
           venue: payload["venue"],
           starts_at: payload["starts_at"],
           ends_at: payload["ends_at"],
           external_id: payload["external_id"],
           created_by_name: payload["created_by_name"],
           created_by_email: payload["created_by_email"],
           source_created_at: payload["source_created_at"],
           synced_at: synced_at
      )
      event.save!
      event
    end

    def resolve_user(payload)
      uin = payload["uin"].to_s.strip.presence
      full_name = [payload["first_name"], payload["last_name"]].map { |value| value.to_s.strip }.compact_blank.join(" ").strip

      user = (User.find_by(recsports_uin: uin) if uin.present?)

      user ||= User.find_by(name: full_name) if full_name.present?
      user ||= User.new(email: generated_email(uin, full_name))

      user.name = full_name.presence || user.name || "Imported Player"
      user.role ||= :player
      user.password = SecureRandom.hex(16) if user.new_record?
      user.recsports_uin = uin if uin.present?
      user.save!
      user
    end

    def generated_email(uin, full_name)
      if uin.present?
        "recsports-#{uin}@attendance.local"
      else
        slug = full_name.to_s.parameterize.presence || "player"
        digest = Digest::SHA256.hexdigest(full_name.to_s)[0, 10]
        "recsports-#{slug}-#{digest}@attendance.local"
      end
    end

    def replace_attendance_rows!(affected_dates)
      return if affected_dates.empty?

      Attendance.recsports.where(date: affected_dates, override_by_leadership: false).delete_all

      grouped_rows = attendance_rows_for_dates(affected_dates).group_by { |row| [row[:user].id, row[:date]] }

      grouped_rows.each_value do |rows|
        date = rows.first[:date]
        next if date.blank?

        Attendance.create!(
             player: rows.first[:user],
             date: date,
             days_attended: rows.size,
             attended: true,
             source: :recsports,
             external_id: rows.map { |row| row[:title] }.join("|"),
             notes: "Imported from RecSports events: #{rows.map { |row| row[:title] }.uniq.join(', ')}"
        )
      end
    end

    def attendance_rows_for_dates(affected_dates)
      recsports_events_for_dates(affected_dates).flat_map do |event|
        event.participants.map do |participant|
          next if event.event_date.blank?

          {
               user: participant.user,
               date: event.event_date,
               title: event.title
          }
        end
      end.compact
    end

    def recsports_events_for_dates(affected_dates)
      start_time = affected_dates.min.beginning_of_day
      end_time = affected_dates.max.end_of_day

      RecsportsEvent
           .includes(participants: :user)
           .where(starts_at: start_time..end_time)
           .select { |event| affected_dates.include?(event.event_date) }
    end

    def deduplicated_participants(participants)
      seen = {}

      Array(participants).filter_map do |participant|
        payload = participant.respond_to?(:stringify_keys) ? participant.stringify_keys : participant.to_h.transform_keys(&:to_s)
        key = participant_dedup_key(payload)
        next if key.blank? || seen[key]

        seen[key] = true
        payload
      end
    end

    def participant_dedup_key(payload)
      uin = payload["uin"].to_s.strip
      return "uin:#{uin}" if uin.present?

      first_name = payload["first_name"].to_s.strip.downcase
      last_name = payload["last_name"].to_s.strip.downcase
      return if first_name.blank? && last_name.blank?

      "name:#{first_name}:#{last_name}"
    end

    def parse_time(value)
      return if value.blank?
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)

      text = value.to_s.strip
      normalized_us_datetime = parse_us_datetime(text)
      return normalized_us_datetime if normalized_us_datetime

      Time.zone.parse(text)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_date(value)
      return if value.blank?
      return value if value.is_a?(Date)

      text = value.to_s.strip
      us_datetime = parse_us_datetime(text)
      return us_datetime.to_date if us_datetime

      us_date = parse_us_date(text)
      return us_date if us_date

      Date.parse(text)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_us_datetime(value)
      [
           "%m/%d/%Y %l:%M %p",
           "%m/%d/%Y %I:%M %p",
           "%m/%d/%Y %H:%M",
           "%m/%d/%Y"
      ].each do |format|
        parsed = Time.zone.strptime(value, format)
        return parsed if parsed
      rescue ArgumentError
        next
      end

      nil
    end

    def parse_us_date(value)
      Date.strptime(value, "%m/%d/%Y")
    rescue ArgumentError
      nil
    end
  end
end
