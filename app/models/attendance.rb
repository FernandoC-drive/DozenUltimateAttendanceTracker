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
  def self.monthly_percent_for(player, date)
    month_scope = where(player: player).for_month(date)
    total_days = date.end_of_month.day
    return 0.0 if total_days.zero?

    attended = month_scope.where("days_attended > 0").count
    (attended.to_f / total_days * 100).round(1)
  end

  def heat_level
    # since each attendance record represents a single day, heat is either 0 or 1
    days_attended.to_i > 0 ? 1 : 0
  end
end
