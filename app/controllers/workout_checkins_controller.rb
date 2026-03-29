class WorkoutCheckinsController < ApplicationController
  before_action :require_login!

  def create
    # Determine which user the workout checkin is for
    target_user = if workout_checkin_params[:player_id].present? && current_user.coach?
                    User.find(workout_checkin_params[:player_id])
                  else
                    current_user
                  end

    # Finds an existing check-in for this specific date, or starts a new one.
    # This smartly prevents the database uniqueness errors we tested for in RSpec!
    checkin = target_user.workout_checkins.find_or_initialize_by(
         workout_date: workout_checkin_params[:workout_date]
    )

    # .update() will either save the new record OR update the existing one.
    # It also safely triggers the mark_week_as_complete callback in your model.
    if checkin.update(workout_checkin_params.except(:player_id).merge(source: 0))
      redirect_to attendances_path(view: "monthly", date: checkin.workout_date, player_id: target_user.id), notice: "Workout check-in saved."
    else
      redirect_to attendances_path, alert: checkin.errors.full_messages.to_sentence
    end
  end

  private

  # Strong Parameters: strictly permits only the date, URL, and player_id
  def workout_checkin_params
    params.require(:workout_checkin).permit(:workout_date, :proof_url, :player_id)
  end
end
