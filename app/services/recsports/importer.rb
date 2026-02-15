module Recsports
  class Importer
    def initialize(rows:)
      @rows = rows
    end

    def call
      @rows.each do |row|
        player = find_player(row)
        next unless player

        date = parse_date(row)
        next unless date

        attendance = Attendance.find_or_initialize_by(player: player, date: date)
        attendance.hours = extract_hours(row)
        attendance.attended = extract_attended(row)
        attendance.source = :recsports
        attendance.external_id = row["id"].presence || row["external_id"].presence
        attendance.notes = row["notes"].presence
        attendance.save!
      end
    end

    private

    def find_player(row)
      email = row["email"].presence || row["player_email"].presence
      return if email.blank?

      User.find_by(email: email.downcase)
    end

    def parse_date(row)
      value = row["date"] || row["practice_date"] || row["submitted_at"]
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def extract_hours(row)
      raw = row["hours"] || row["attendance_hours"] || 0
      Float(raw)
    rescue ArgumentError, TypeError
      0
    end

    def extract_attended(row)
      raw = row["attended"] || row["present"] || row["status"]
      return true if raw.to_s.strip.casecmp("present").zero?
      return false if raw.to_s.strip.casecmp("absent").zero?

      ActiveModel::Type::Boolean.new.cast(raw)
    end
  end
end
