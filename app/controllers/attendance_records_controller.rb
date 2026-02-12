class AttendanceRecordsController < ApplicationController
  before_action :set_attendance_record, only: %i[ show edit update destroy ]

  # GET /attendance_records or /attendance_records.json
  def index
    @attendance_records = AttendanceRecord.all
  end

  # GET /attendance_records/1 or /attendance_records/1.json
  def show
  end

  # GET /attendance_records/new
  def new
    @attendance_record = AttendanceRecord.new
  end

  # GET /attendance_records/1/edit
  def edit
  end

  # POST /attendance_records or /attendance_records.json
  def create
    @attendance_record = AttendanceRecord.new(attendance_record_params)

    respond_to do |format|
      if @attendance_record.save
        format.html { redirect_to @attendance_record, notice: "Attendance record was successfully created." }
        format.json { render :show, status: :created, location: @attendance_record }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @attendance_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attendance_records/1 or /attendance_records/1.json
  def update
    respond_to do |format|
      if @attendance_record.update(attendance_record_params)
        format.html { redirect_to @attendance_record, notice: "Attendance record was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @attendance_record }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @attendance_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attendance_records/1 or /attendance_records/1.json
  def destroy
    @attendance_record.destroy!

    respond_to do |format|
      format.html { redirect_to attendance_records_path, notice: "Attendance record was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attendance_record
      @attendance_record = AttendanceRecord.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def attendance_record_params
      params.expect(attendance_record: [ :member_id, :date, :is_present ])
    end
end
