class AttendancesController < ApplicationController
  before_action :require_login!

  VIEW_MODES = %w[daily weekly monthly calendar].freeze
  COLOR_PROFILES = %w[default red_green_safe tritanopia_safe monochrome].freeze

  def index
    @view_mode = params[:view].presence_in(VIEW_MODES) || "monthly"
    @color_profile = params[:color_profile].presence_in(COLOR_PROFILES) || "red_green_safe"
    @selected_date = parse_date(params[:date])

    @workout_month = params[:workout_month].present? ? Date.parse(params[:workout_month]) : Time.zone.today

    @workout_checkins = WorkoutCheckin.where(
        player: current_user, 
        workout_date: @workout_month.beginning_of_month..@workout_month.end_of_month
    ).order(workout_date: :desc)

    # everyone can optionally pick a player to view; coaches and players alike
    @players = User.where(role: :player).order(:name)
    @selected_player = User.find_by(id: params[:player_id]) if params[:player_id].present?

    # coaches generally want to toggle someone’s attendance; if they haven’t
    # picked anyone explicitly we default to the first player so that the
    # calendar/swap buttons are always rendered. (non‑coach users keep the
    # behaviour of showing every record when the selector is blank.)
    if current_user.coach == true && @selected_player.nil? && @players.any?
      @selected_player = @players.first
    end
    # players and coaches can still explicitly leave the selector blank if they
    # really want to see everything, but coaches now get a sensible default

    scope = Attendance.includes(:player)
    scope = scope.where(player: @selected_player) if @selected_player
    @attendances = filter_scope(scope)

    if @selected_player
      @percent_attended = Attendance.monthly_percent_for(@selected_player, @selected_date)
      month_scope = Attendance.where(player: @selected_player).for_month(@selected_date)
      @calendar_attendances = month_scope.index_by(&:date)
    end

    @workout_checkins = current_user.coach? ? WorkoutCheckin.none : current_user.workout_checkins.where(workout_date: @selected_date.beginning_of_month..@selected_date.end_of_month)
  end

  def toggle
    if params[:id].present?
      @attendance = Attendance.find(params[:id])
    else
      # allow toggling/creating attendance by date/player pair (used in calendar view)
      date = parse_date(params[:date])
      player = User.find(params[:player_id])
      @attendance = Attendance.find_or_initialize_by(player: player, date: date)
    end

    # use the boolean `coach` column rather than enum, since the latter only
    # reflects the user's role and may remain `player` even when the coach view
    # flag has been toggled.
    if current_user.coach == true
      # flip the status, default to true when creating new record
      if @attendance.new_record?
        @attendance.attended = true
        @attendance.days_attended = 1
        @attendance.save!
      else
        @attendance.toggle_status!
      end

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
      # monthly and calendar both use month filter
      scope.for_month(@selected_date)
    end.order(date: :desc)
  end
end
