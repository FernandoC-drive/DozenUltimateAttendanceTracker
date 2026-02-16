class WeeklyWorkoutsController < ApplicationController
  before_action :set_weekly_workout, only: %i[ show edit update destroy ]

  # GET /weekly_workouts or /weekly_workouts.json
  def index
    @weekly_workouts = WeeklyWorkout.all
  end

  # GET /weekly_workouts/1 or /weekly_workouts/1.json
  def show
  end

  # GET /weekly_workouts/new
  def new
    @weekly_workout = WeeklyWorkout.new
  end

  # GET /weekly_workouts/1/edit
  def edit
  end

  # POST /weekly_workouts or /weekly_workouts.json
  def create
    @weekly_workout = WeeklyWorkout.new(weekly_workout_params)

    respond_to do |format|
      if @weekly_workout.save
        format.html { redirect_to @weekly_workout, notice: "Weekly workout was successfully created." }
        format.json { render :show, status: :created, location: @weekly_workout }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @weekly_workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /weekly_workouts/1 or /weekly_workouts/1.json
  def update
    respond_to do |format|
      if @weekly_workout.update(weekly_workout_params)
        format.html { redirect_to @weekly_workout, notice: "Weekly workout was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @weekly_workout }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @weekly_workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /weekly_workouts/1 or /weekly_workouts/1.json
  def destroy
    @weekly_workout.destroy!

    respond_to do |format|
      format.html { redirect_to weekly_workouts_path, notice: "Weekly workout was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_weekly_workout
      @weekly_workout = WeeklyWorkout.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def weekly_workout_params
      params.expect(weekly_workout: [ :member_id, :week_start_date, :complete ])
    end
end
