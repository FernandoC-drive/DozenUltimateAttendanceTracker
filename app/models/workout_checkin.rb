class WorkoutCheckin < ApplicationRecord
  belongs_to :player, class_name: "User", inverse_of: :workout_checkins

  enum :source, { manual: 0, slack: 1 }, default: :manual

  validates :workout_date, presence: true
  validates :workout_date, uniqueness: { scope: :player_id }
end
