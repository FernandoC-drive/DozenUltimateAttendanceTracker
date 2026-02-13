class WorkoutCheckinsController < ApplicationController
  before_action :require_login!

  def create
    checkin = current_user.workout_checkins.find_or_initialize_by(workout_date: workout_checkin_params[:workout_date])

    if checkin.update(workout_checkin_params.merge(source: :manual))
      redirect_to attendances_path(view: "monthly", date: checkin.workout_date), notice: "Workout check-in saved."
    else
      redirect_to attendances_path, alert: checkin.errors.full_messages.to_sentence
    end
  end

  private

  def workout_checkin_params
    params.require(:workout_checkin).permit(:workout_date, :proof_url)
  end
end
