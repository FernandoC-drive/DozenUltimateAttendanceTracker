require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  setup do
    @player = User.create!(name: "Player One", email: "player1@example.com", role: :player, password: "password")
  end

  test "rejects negative hours" do
    attendance = Attendance.new(player: @player, date: Date.current, hours: -1)

    assert_not attendance.valid?
    assert_includes attendance.errors[:hours], "Invalid attendance hours."
  end

  test "rejects non numeric hours" do
    attendance = Attendance.new(player: @player, date: Date.current)
    attendance.hours = "abc"

    assert_not attendance.valid?
    assert_includes attendance.errors[:hours], "Invalid attendance hours."
  end
end
