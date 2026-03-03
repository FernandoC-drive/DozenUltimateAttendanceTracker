require "test_helper"

class AdminAttendanceUpdatesTest < ActionDispatch::IntegrationTest
  setup do
    # ensure unique users in case database retains rows between runs
    unique = SecureRandom.hex(4)
    @coach = User.create!(name: "Coach", email: "coach#{unique}@example.com", password: "password", role: 1, coach: true)
    @player = User.create!(name: "Player", email: "player#{unique}@example.com", password: "password", role: 0)
    @attendance = Attendance.create!(player: @player, date: Date.current, days_attended: 1, attended: true)
  end

  test "coach can update attendance and player sees it" do
    sign_in(@coach)

    patch admin_attendance_path(@attendance), params: { attendance: { days_attended: "2", attended: "1", notes: "Updated" } }
    follow_redirect!

    assert_includes response.body, "Attendance updated successfully."

    delete session_path
    sign_in(@player)

    get attendances_path(view: "daily", date: Date.current.to_s)

    # after updating to 2 days attended the daily list should show 2
    assert_includes response.body, "2"
  end

  test "coach sees a default player selection" do
    sign_in(@coach)
    get attendances_path
    # response should render summary for the very first player
    first_name = User.where(role: :player).order(:name).first.name
    assert_includes response.body, first_name
  end

  test "invalid days shows required error" do
    sign_in(@coach)

    patch admin_attendance_path(@attendance), params: { attendance: { days_attended: "-3" } }
    follow_redirect!

    assert_includes response.body, "must be greater than or equal to 0"

    patch admin_attendance_path(@attendance), params: { attendance: { days_attended: "abc" } }
    follow_redirect!

    assert_includes response.body, "is not a number"
  end

  private

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }

    if user.role == "coach"
      user.reload
      assert user.coach, "coach flag should have been true after logging in"
    end
  end
end
