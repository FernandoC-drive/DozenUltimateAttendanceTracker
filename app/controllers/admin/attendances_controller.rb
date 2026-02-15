module Admin
  class AttendancesController < BaseController
    def index
      @selected_date = parse_date(params[:date])
      @players = User.player.order(:name)
      @attendances = Attendance.includes(:player).for_month(@selected_date).order(date: :desc)
      @attendance = Attendance.new(date: @selected_date)
    end

    def create
      attendance = Attendance.find_or_initialize_by(player_id: attendance_create_params[:player_id], date: attendance_create_params[:date])

      if attendance.update(attendance_create_params.slice(:hours, :attended, :notes).merge(override_by_leadership: true, source: :manual))
        redirect_to admin_attendances_path(date: attendance.date), notice: "Attendance updated successfully."
      else
        message = attendance.errors[:hours].include?(Attendance::INVALID_HOURS_MESSAGE) ? Attendance::INVALID_HOURS_MESSAGE : attendance.errors.full_messages.to_sentence
        redirect_to admin_attendances_path(date: attendance_create_params[:date]), alert: message
      end
    end

    def update
      attendance = Attendance.find(params[:id])

      if attendance.update(attendance_params.merge(override_by_leadership: true, source: :manual))
        redirect_to admin_attendances_path(date: attendance.date), notice: "Attendance updated successfully."
      else
        message = attendance.errors[:hours].include?(Attendance::INVALID_HOURS_MESSAGE) ? Attendance::INVALID_HOURS_MESSAGE : attendance.errors.full_messages.to_sentence
        redirect_to admin_attendances_path(date: attendance.date), alert: message
      end
    end

    private

    def attendance_params
      params.require(:attendance).permit(:hours, :attended, :notes)
    end

    def attendance_create_params
      params.require(:attendance).permit(:player_id, :date, :hours, :attended, :notes)
    end

    def parse_date(raw)
      Date.parse(raw.to_s)
    rescue ArgumentError
      Date.current
    end
  end
end
