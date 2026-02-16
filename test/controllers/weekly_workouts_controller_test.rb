require "test_helper"

class WeeklyWorkoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @weekly_workout = weekly_workouts(:one)
  end

  test "should get index" do
    get weekly_workouts_url
    assert_response :success
  end

  test "should get new" do
    get new_weekly_workout_url
    assert_response :success
  end

  test "should create weekly_workout" do
    assert_difference("WeeklyWorkout.count") do
      post weekly_workouts_url, params: { weekly_workout: { complete: @weekly_workout.complete, member_id: @weekly_workout.member_id, week_start_date: @weekly_workout.week_start_date } }
    end

    assert_redirected_to weekly_workout_url(WeeklyWorkout.last)
  end

  test "should show weekly_workout" do
    get weekly_workout_url(@weekly_workout)
    assert_response :success
  end

  test "should get edit" do
    get edit_weekly_workout_url(@weekly_workout)
    assert_response :success
  end

  test "should update weekly_workout" do
    patch weekly_workout_url(@weekly_workout), params: { weekly_workout: { complete: @weekly_workout.complete, member_id: @weekly_workout.member_id, week_start_date: @weekly_workout.week_start_date } }
    assert_redirected_to weekly_workout_url(@weekly_workout)
  end

  test "should destroy weekly_workout" do
    assert_difference("WeeklyWorkout.count", -1) do
      delete weekly_workout_url(@weekly_workout)
    end

    assert_redirected_to weekly_workouts_url
  end
end
