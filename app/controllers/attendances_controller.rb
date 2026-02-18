class AttendancesController < ApplicationController
  before_action :require_login!

def index
  @view_mode = params[:view].presence_in(%w[daily weekly monthly]) || "monthly"
  @selected_date = parse_date(params[:date])

  scope = Attendance.includes(:player)
  @attendances = filter_scope(scope)

  @workout_checkins = current_user.coach == true ? WorkoutCheckin.none : current_user.workout_checkins.where(workout_date: @selected_date.beginning_of_month..@selected_date.end_of_month)
end

def toggle
    @attendance = Attendance.find(params[:id])
    
    # Check if the logged-in user is a coach before allowing the change
    if current_user.coach?
      @attendance.toggle_status!
      # redirect_back keeps them on the same page they clicked the button from
      redirect_back(fallback_location: attendances_path, notice: "Attendance updated successfully.")
    else
      redirect_back(fallback_location: attendances_path, alert: "Only coaches can edit attendance.")
    end
  end

  private

  def parse_date(raw)
    Date.parse(raw.to_s)
  rescue ArgumentError
    Date.current
  end

  def filter_scope(scope)
    case @view_mode
    when "daily"
      scope.for_day(@selected_date)
    when "weekly"
      scope.for_week(@selected_date)
    else
      scope.for_month(@selected_date)
    end.order(date: :desc)
  end
end