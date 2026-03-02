require "application_system_test_case"

class AttendancesTest < ApplicationSystemTestCase
  setup do
    @coach = User.create!(name: "Coach", email: "coach2@example.com", password: "password", role: 1, coach: true)
    @player = User.create!(name: "Player2", email: "player2@example.com", password: "password", role: 0)
    Attendance.create!(player: @player, date: Date.current.beginning_of_month, hours: 1.0, attended: true)
  end

  def sign_in(user)
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_on "Log in"
  end

  test "coach sees calendar and can toggle days" do
    sign_in(@coach)

    visit attendances_path
    # choose the player and calendar view
    select @player.name, from: "Player"
    select "Calendar", from: "View"
    click_on "Apply"

    assert_selector ".attendance-summary"
    assert_selector ".calendar"

    # toggle the first day
    first_day_link = find(".toggle-link", match: :first)
    first_day_link.click

    # after toggling, the page should refresh and show updated status
    assert_selector ".calendar"
  end

  test "player can view other players' attendance" do
    other = User.create!(name: "OtherPlayer", email: "other@tamu.edu", password: "password", role: 0)
    Attendance.create!(player: other, date: Date.current.beginning_of_month, hours: 2.0, attended: false)

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
  endend