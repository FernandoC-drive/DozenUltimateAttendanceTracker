class WorkoutCheckin < ApplicationRecord
  belongs_to :player, class_name: 'User'
  has_one_attached :proof_image

  validates :workout_date, presence: true
  validates :workout_date, uniqueness: { scope: :player_id, message: "has already been logged" }
  validates :proof_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  validates :proof_image,
            content_type: ['image/png', 'image/jpeg'],
            size: { less_than: 5.megabytes, message: 'is too large (max 5MB)' }

  after_create_commit :sync_weekly_completion_status
  after_destroy_commit :sync_weekly_completion_status

  private

  def sync_weekly_completion_status
    week_start = workout_date.beginning_of_week(:monday)
    week_end = workout_date.end_of_week(:monday)

    # Count workouts for this player between Monday and Sunday
    weekly_workout_count = WorkoutCheckin.where(
      player_id: player_id,
      workout_date: week_start..week_end
    ).count

    # Required workouts to trigger the checkmark
    is_complete = weekly_workout_count >= 2

    # Find or create the weekly tracker
    weekly_workout = WeeklyWorkout.find_or_create_by!(
      player_id: player_id,
      week_start_date: week_start
    )

    weekly_workout.update!(complete: is_complete)
  end
end