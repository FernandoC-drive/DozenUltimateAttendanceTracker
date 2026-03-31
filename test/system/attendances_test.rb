require "application_system_test_case"

class AttendancesTest < ApplicationSystemTestCase
  setup do
    @coach = User.create!(name: "Coach", email: "coach2@tamu.edu", password: "password", role: 1, coach: true)
    @player = User.create!(name: "Player2", email: "player2@tamu.edu", password: "password", role: 0)
    Attendance.create!(player: @player, date: Date.current.beginning_of_month, days_attended: 1, attended: true)
  end

  def sign_in(user)
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_on "Log in"

    return unless user.role == "coach"

    user.reload
    assert user.coach, "coach flag should be set after login"
  end

  test "coach sees calendar and can toggle days" do
    sign_in(@coach)

    # we no longer need to pick a player manually; the controller defaults to
    # the first one for coaches. we still explicitly request calendar view
    visit attendances_path(view: "calendar")

    assert_selector ".attendance-summary"
    assert_selector ".calendar"
    assert_selector "button.toggle-link", text: "Toggle"

    # toggle the first day
    first_day_button = find(".toggle-link", match: :first)
    first_day_button.click

    # after toggling, the page should refresh and show updated status
    assert_selector ".calendar"
  end

  test "coach sees swap buttons without selecting player" do
    sign_in(@coach)
    visit attendances_path(view: "daily")

    # at least one attendance row should exist (we created @player in setup)
    assert_selector "button", text: "Swap"
  end

  test "player can view other players' attendance" do
    other = User.create!(name: "OtherPlayer", email: "other@tamu.edu", password: "password", role: 0)
    Attendance.create!(player: other, date: Date.current.beginning_of_month, days_attended: 0, attended: false)

    sign_in(@player)

    visit attendances_path
    # initially should see both players' entries
    assert_text "Player2"
    assert_text "OtherPlayer"

    # filter down to other player only
    select "OtherPlayer", from: "Player"
    click_on "Apply"
    assert_text "OtherPlayer"
    assert_no_text "Player2"
  end

  test "coach can toggle from table view" do
    sign_in(@coach)
    visit attendances_path
    select @player.name, from: "Player"
    click_on "Apply"

    assert_selector "button", text: "Swap"
    click_on "Swap", match: :first
    assert_text "Attendance updated successfully."
  end
end