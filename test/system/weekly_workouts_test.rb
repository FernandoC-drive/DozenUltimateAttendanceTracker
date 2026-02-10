require "application_system_test_case"

class WeeklyWorkoutsTest < ApplicationSystemTestCase
  setup do
    @weekly_workout = weekly_workouts(:one)
  end

  test "visiting the index" do
    visit weekly_workouts_url
    assert_selector "h1", text: "Weekly workouts"
  end

  test "should create weekly workout" do
    visit weekly_workouts_url
    click_on "New weekly workout"

    check "Complete" if @weekly_workout.complete
    fill_in "Member", with: @weekly_workout.member_id
    fill_in "Week start date", with: @weekly_workout.week_start_date
    click_on "Create Weekly workout"

    assert_text "Weekly workout was successfully created"
    click_on "Back"
  end

  test "should update Weekly workout" do
    visit weekly_workout_url(@weekly_workout)
    click_on "Edit this weekly workout", match: :first

    check "Complete" if @weekly_workout.complete
    fill_in "Member", with: @weekly_workout.member_id
    fill_in "Week start date", with: @weekly_workout.week_start_date
    click_on "Update Weekly workout"

    assert_text "Weekly workout was successfully updated"
    click_on "Back"
  end

  test "should destroy Weekly workout" do
    visit weekly_workout_url(@weekly_workout)
    click_on "Destroy this weekly workout", match: :first

    assert_text "Weekly workout was successfully destroyed"
  end
end
