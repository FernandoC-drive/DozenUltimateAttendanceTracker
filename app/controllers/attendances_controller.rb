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
    
    # Calculate aggregated attendance by player and timeframe
    @attendance_summary = calculate_attendance_summary(scope)
    @date_range = get_date_range

    if @selected_player
      @percent_attended = Attendance.monthly_percent_for(@selected_player, @selected_date)
      month_scope = Attendance.where(player: @selected_player).for_month(@selected_date)
      @calendar_attendances = month_scope.index_by(&:date)
    else
      # Generate all-player calendar view showing attendance counts per day
      @attendance_counts_by_day = calculate_attendance_counts_by_day
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

  def calculate_attendance_summary(scope)
    # Get the appropriate date range based on view mode
    date_range = case @view_mode
                 when "daily"
                   @selected_date..@selected_date
                 when "weekly"
                   @selected_date.beginning_of_week(:monday)..@selected_date.end_of_week(:sunday)
                 else
                   # monthly and calendar
                   @selected_date.beginning_of_month..@selected_date.end_of_month
                 end
    
    # Filter to only Monday (1), Wednesday (3), and Friday (5)
    mwf_dates = (date_range.begin..date_range.end).select { |d| [1, 3, 5].include?(d.wday) }
    
    # Get all players in the system (or just the selected player if one is chosen)
    players_to_query = @selected_player ? [@selected_player] : User.where(role: :player).order(:name)
    
    # Build summary for each player with attendance within the date range (M/W/F only)
    summary = players_to_query.map do |player|
      attendance_records = Attendance.where(player: player, date: mwf_dates)
      total_days_attended = attendance_records.where("days_attended > 0").sum(:days_attended)
      total_possible_days = mwf_dates.count
      percent = total_possible_days > 0 ? ((total_days_attended.to_f / total_possible_days) * 100).round(1) : 0.0
      
      {
        player: player,
        total_days_attended: total_days_attended,
        total_possible_days: total_possible_days,
        percent_attended: percent
      }
    end
    
    summary
  end

  def get_date_range
    case @view_mode
    when "daily"
      { start: @selected_date, end: @selected_date, label: @selected_date.strftime("%A, %B %d, %Y") + " (M/W/F only)" }
    when "weekly"
      start_date = @selected_date.beginning_of_week(:monday)
      end_date = @selected_date.end_of_week(:sunday)
      { start: start_date, end: end_date, label: "Week of #{start_date.strftime('%B %d')} - #{end_date.strftime('%B %d, %Y')} (M/W/F only)" }
    else
      # monthly
      start_date = @selected_date.beginning_of_month
      end_date = @selected_date.end_of_month
      { start: start_date, end: end_date, label: @selected_date.strftime("%B %Y") + " (M/W/F only)" }
    end
  end

  def calculate_attendance_counts_by_day
    month_start = @selected_date.beginning_of_month
    month_end = @selected_date.end_of_month
    
    # Get all attendance records for the month for all players
    month_attendances = Attendance.where(date: month_start..month_end).where("days_attended > 0")
    
    # Group by date and count attendees per day
    counts_by_day = {}
    (month_start..month_end).each do |date|
      counts_by_day[date] = month_attendances.where(date: date).count
    end
    
    counts_by_day
  end
end
