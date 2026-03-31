require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  setup do
    @player = User.create!(name: "Player One", email: "player1@tamu.edu", password: "password", role: 0)
  end

  test "rejects negative days" do
    attendance = Attendance.new(player: @player, date: Date.current, days_attended: -1)

    assert_not attendance.valid?
    assert_includes attendance.errors[:days_attended], "must be greater than or equal to 0"
  end

  test "rejects non integer days" do
    attendance = Attendance.new(player: @player, date: Date.current)
    attendance.days_attended = 1.5

    assert_not attendance.valid?
    assert_includes attendance.errors[:days_attended], "must be an integer"
  end
end
