class Attendance < ApplicationRecord
  belongs_to :player, class_name: "User", inverse_of: :attendances

  enum :source, { manual: 0, recsports: 1 }, default: :manual

  validates :date, presence: true
  validates :date, uniqueness: { scope: :player_id }
  validates :days_attended, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def toggle_status!
    if days_attended.to_i <= 0
      update(days_attended: 1, attended: true)
    else
      update(days_attended: 0, attended: false)
    end
  end

  scope :for_day, ->(date) { where(date: date) }
  scope :for_week, ->(date) { where(date: date.beginning_of_week..date.end_of_week) }
  scope :for_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }

  # returns percentage of days attended for a given player/month (0.0..100.0)
  # only counts Monday, Wednesday, and Friday
  def self.monthly_percent_for(player, date)
    month_start = date.beginning_of_month
    month_end = date.end_of_month

    # Ask the database which days are active
    practice_days = TeamSetting.current.practice_days_ints

    # Filter the month down to only those specific days
    possible_dates = (month_start..month_end).select { |d| practice_days.include?(d.wday) }

    return 0.0 if possible_dates.empty?

    # Count how many of those specific dates the player attended
    total_attended = where(player: player, date: possible_dates, attended: true).count

    # Return the calculated percentage
    ((total_attended.to_f / possible_dates.count) * 100).round(1)
  end

  def heat_level
    # since each attendance record represents a single day, heat is either 0 or 1
    days_attended.to_i.positive? ? 1 : 0
  end
end
