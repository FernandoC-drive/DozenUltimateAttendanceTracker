class WorkoutCheckinsController < ApplicationController
  before_action :require_login!

  def create
    # Finds an existing check-in for this specific date, or starts a new one.
    # This smartly prevents the database uniqueness errors we tested for in RSpec!
    checkin = current_user.workout_checkins.find_or_initialize_by(
         workout_date: workout_checkin_params[:workout_date]
    )

    # .update() will either save the new record OR update the existing one.
    # It also safely triggers the mark_week_as_complete callback in your model.
    if checkin.update(workout_checkin_params.merge(source: 0))
      redirect_to attendances_path(view: "monthly", date: checkin.workout_date), notice: "Workout check-in saved."
    else
      redirect_to attendances_path, alert: checkin.errors.full_messages.to_sentence
    end
  end

  private

  # Strong Parameters: strictly permits only the date and the URL
  def workout_checkin_params
    params.require(:workout_checkin).permit(:workout_date, :proof_url)
  end
end
