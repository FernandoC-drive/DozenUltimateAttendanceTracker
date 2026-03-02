class WorkoutCheckin < ApplicationRecord
  belongs_to :player, class_name: 'User'

  validates :workout_date, presence: true
  validates :workout_date, uniqueness: { scope: :player_id, message: "has already been logged" }
  validates :proof_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  after_create_commit :mark_week_as_complete

  private

  def mark_week_as_complete
    # Define the start of the week (defaults to Monday in Rails)
    week_start = workout_date.beginning_of_week

    # find_or_create_by ensures we don't accidentally make duplicate week records
    weekly_workout = WeeklyWorkout.find_or_create_by!(
      player_id: player_id,
      week_start_date: week_start
    )

    # Mark the week as complete
    weekly_workout.update!(complete: true)
  end
end