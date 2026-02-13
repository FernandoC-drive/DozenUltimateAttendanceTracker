class Attendance < ApplicationRecord
  INVALID_HOURS_MESSAGE = "Invalid attendance hours.".freeze

  belongs_to :player, class_name: "User", inverse_of: :attendances

  enum :source, { manual: 0, recsports: 1 }, default: :manual

  validates :date, presence: true
  validates :date, uniqueness: { scope: :player_id }
  validate :hours_must_be_non_negative_number

  scope :for_day, ->(date) { where(date: date) }
  scope :for_week, lambda { |date|
    beginning = date.beginning_of_week(:monday)
    where(date: beginning..beginning.end_of_week(:sunday))
  }
  scope :for_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }

  def heat_level
    return 0 if hours.to_f <= 0
    return 1 if hours.to_f < 1.5
    return 2 if hours.to_f < 3

    3
  end

  private

  def hours_must_be_non_negative_number
    number = Float(hours_before_type_cast)
    errors.add(:hours, INVALID_HOURS_MESSAGE) if number.negative?
  rescue ArgumentError, TypeError
    errors.add(:hours, INVALID_HOURS_MESSAGE)
  end
end
