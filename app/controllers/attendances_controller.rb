class AttendancesController < ApplicationController
  # Coach can toggle workout completion for a player/week
  def toggle_workout_complete
    # You may want to use your own auth logic here
    player = User.find(params[:player_id])
    week_start = Date.parse(params[:week_start])
    weekly = WeeklyWorkout.find_or_create_by!(player: player, week_start_date: week_start)
    weekly.update!(complete: !weekly.complete)
    redirect_back(fallback_location: attendances_path, notice: "Workout completion updated.")
  end
  before_action :require_login!

  VIEW_MODES = %w[daily weekly monthly calendar].freeze
  COLOR_PROFILES = %w[default red_green_safe tritanopia_safe monochrome].freeze

  def index
    @view_mode = params[:view].presence_in(VIEW_MODES) || "calendar"
    @color_profile = params[:color_profile].presence_in(COLOR_PROFILES) || "default"
    @selected_date = parse_date(params[:date])

    # everyone can optionally pick a player to view
    @players = User.where(role: :player).order(:name)
    @selected_player = if params.key?(:player_id)
                         User.find_by(id: params[:player_id])
                       else
                         # Initial page load, default to the current user if they are a player.
                         current_user.player? ? current_user : nil
                       end
    @recent_recsports_events = RecsportsEvent.includes(participants: :user).recent_first.limit(5)

    @chart_month = params[:chart_month].present? ? Date.parse(params[:chart_month]) : Date.today
    @workout_chart_data = workout_chart_data  # private method from the snippet

    # coaches can view all players by leaving player selector blank, or pick one player.
    # NB: we no longer auto-select the first player for coaches so "all players" works.

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

    @workout_month = if params[:workout_month].present?
                       Date.parse(params[:workout_month])
                     else
                       Date.today
                     end

    @workout_checkins = if @selected_player
                          # When viewing a specific player, show their workout checkins
                          @selected_player.workout_checkins.where(workout_date: @workout_month.beginning_of_month..@workout_month.end_of_month)
                        else
                          # If no player is selected, show nothing
                          WorkoutCheckin.none
                        end
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

    # use the role enum to check if user is a coach
    if current_user.coach?
      # flip the status, default to true when creating new record
      if @attendance.new_record?
        @attendance.attended = true
        @attendance.days_attended = 1
        @attendance.save!
      else
        @attendance.toggle_status!
      end

      status_word = @attendance.attended ? "present" : "absent"

        redirect_back(fallback_location: attendances_path, notice: "Successfully marked #{status_word}!")
      else
        redirect_back(fallback_location: attendances_path, alert: "Only coaches can edit attendance.")
      end
  end

  private

  def parse_date(raw)
    raw_str = raw.to_s.strip
    return Date.current if raw_str.blank?
    
    if raw_str.match?(/\A\d{4}-\d{2}\z/)
      # Formats "2026-02" (from the Monthly view) into "2026-02-01" so Ruby can read it
      Date.parse("#{raw_str}-01")
    elsif raw_str.match?(/\A\d{4}-W\d{2}\z/)
      # Formats "2026-W13" (from the Weekly view) into the Monday of that specific week
      Date.strptime("#{raw_str}-1", "%G-W%V-%u")
    else
      # Handles standard "2026-03-29" from the Daily view
      Date.parse(raw_str)
    end
  rescue ArgumentError, TypeError
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

  private

  def workout_chart_data
    month   = (@chart_month || Date.today).beginning_of_month
    players = User.order(:name)
    weeks   = (0..((month.end_of_month - month.beginning_of_week(:monday)).to_i / 7))
                .map { |i| month.beginning_of_week(:monday) + i.weeks }
                .select { |w| w <= month.end_of_month }

    weeks.map do |week_start|
      completed = WeeklyWorkout.where(week_start_date: week_start, complete: true).count
      { week: week_start.strftime("%-m/%-d"), completed: completed, total: players.count }
    end
  end


  def calculate_attendance_summary(scope)
    date_range = case @view_mode
                 when "daily"
                   @selected_date..@selected_date
                 when "weekly"
                   @selected_date.beginning_of_week(:monday)..@selected_date.end_of_week(:sunday)
                 else
                   @selected_date.beginning_of_month..@selected_date.end_of_month
                 end

    mwf_dates = (date_range.begin..date_range.end).select { |d| TeamSetting.current.practice_days_ints.include?(d.wday) }
    players_to_query = @selected_player ? [@selected_player] : User.where(role: :player).order(:name)

    target_week_start = case @view_mode
                        when "weekly"
                          @selected_date.beginning_of_week(:monday)
                        else
                          if @selected_date.beginning_of_month == Date.current.beginning_of_month
                            Date.current.beginning_of_week(:monday)
                          else
                            @selected_date.end_of_month.beginning_of_week(:monday)
                          end
                        end

    # Fetch DB records (respects Coach manual overrides)
    weekly_workouts = WeeklyWorkout.where(
      player_id: players_to_query.map(&:id), 
      week_start_date: target_week_start
    ).index_by(&:player_id)

    # Dynamically count actual workouts for the target week
    target_week_end = target_week_start.end_of_week(:monday)
    actual_workout_counts = WorkoutCheckin.where(
      player_id: players_to_query.map(&:id),
      workout_date: target_week_start..target_week_end
    ).group(:player_id).count

    summary = players_to_query.map do |player|
      attendance_records = Attendance.where(player: player, date: mwf_dates)
      total_days_attended = attendance_records.where("days_attended > 0").sum(:days_attended)
      total_possible_days = mwf_dates.count
      percent = total_possible_days > 0 ? ((total_days_attended.to_f / total_possible_days) * 100).round(1) : 0.0

      db_record = weekly_workouts[player.id]
      
      is_complete = if db_record.present?
                      db_record.complete
                    else
                      (actual_workout_counts[player.id] || 0) >= 2
                    end

      {
        player: player,
        total_days_attended: total_days_attended,
        total_possible_days: total_possible_days,
        percent_attended: percent,
        workout_complete: is_complete,
        target_week_start: target_week_start 
      }
    end

    sort_param = params[:sort] || 'name_asc'
    
    case sort_param
    when 'name_desc'
      summary.sort_by! { |s| s[:player].name }.reverse!
    when 'percent_asc'
      # Sorts by percentage first, then alphabetically for ties
      summary.sort_by! { |s| [s[:percent_attended], s[:player].name] }
    when 'percent_desc'
      summary.sort_by! { |s| [s[:percent_attended], s[:player].name] }.reverse!
    else
      summary.sort_by! { |s| s[:player].name }
    end

    summary
  end

  def get_date_range
    case @view_mode
    when "daily"
      { start: @selected_date, end: @selected_date, label: @selected_date.strftime("%A, %B %d, %Y") + " (M/W/F only)" }
    when "weekly"
      start_date = @selected_date.beginning_of_week(:monday)
      end_date = @selected_date.end_of_week(:monday)
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

  def update_settings
    setting = TeamSetting.current
    
    # We use 'params[:practice_days] || []' so if the coach unchecks EVERY box, 
    # it saves an empty array instead of throwing a nil error!
    setting.update(practice_days: params[:practice_days] || [])
    
    redirect_back fallback_location: admin_attendances_path, notice: "Practice days updated successfully!"
  end
  
end
