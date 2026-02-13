require "test_helper"

class AdminAttendanceUpdatesTest < ActionDispatch::IntegrationTest
  setup do
    @coach = User.create!(name: "Coach", email: "coach@example.com", role: :coach, password: "password")
    @player = User.create!(name: "Player", email: "player@example.com", role: :player, password: "password")
    @attendance = Attendance.create!(player: @player, date: Date.current, hours: 1.0, attended: true)
  end

  test "coach can update attendance and player sees it" do
    sign_in(@coach)

    patch admin_attendance_path(@attendance), params: { attendance: { hours: "2.5", attended: "1", notes: "Updated" } }
    follow_redirect!

    assert_includes response.body, "Attendance updated successfully."

    delete session_path
    sign_in(@player)

    get attendances_path(view: "daily", date: Date.current.to_s)

    assert_includes response.body, "2.5"
  end

  test "invalid hours shows required error" do
    sign_in(@coach)

    patch admin_attendance_path(@attendance), params: { attendance: { hours: "-3" } }
    follow_redirect!

    assert_includes response.body, "Invalid attendance hours."

    patch admin_attendance_path(@attendance), params: { attendance: { hours: "abc" } }
    follow_redirect!

    assert_includes response.body, "Invalid attendance hours."
  end

  private

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end
end
