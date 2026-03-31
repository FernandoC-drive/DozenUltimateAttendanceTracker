require "application_system_test_case"

class AttendanceRecordsTest < ApplicationSystemTestCase
  setup do
    @attendance_record = attendance_records(:one)
    # create coach user for toggling actions
    @coach = User.create!(name: "Coach", email: "coach_records@tamu.edu", password: "password", role: 1, coach: true)
  end

  def sign_in(user)
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_on "Log in"

    # ensure the coach flag was set for coach-role accounts
    return unless user.role == "coach"

    user.reload
    assert user.coach, "expected coach flag to be true after login"
  end

  test "visiting the index" do
    visit attendance_records_url
    assert_selector "h1", text: "Attendance records"
  end

  test "coach can toggle attendance record" do
    sign_in(@coach)

    visit attendance_records_url
    record_div_id = "attendance_record_#{@attendance_record.id}"
    record_text = find("div##{record_div_id} p:nth-of-type(3)").text
    assert_match(/Is present: (true|false)/, record_text)
    initial = record_text.include?("true")

    # click the toggle button for that record
    within("div##{record_div_id}") do
      click_on "Toggle"
    end

    # expect flash notice and boolean flipped
    assert_text "Attendance toggled successfully."
    updated_text = find("div##{record_div_id} p:nth-of-type(3)").text
    assert_equal(!initial, updated_text.include?("true"))
  end

  test "should create attendance record" do
    visit attendance_records_url
    click_on "New attendance record"

    fill_in "Date", with: @attendance_record.date
    check "Is present" if @attendance_record.is_present
    fill_in "Member", with: @attendance_record.member_id
    click_on "Create Attendance record"

    assert_text "Attendance record was successfully created"
    click_on "Back"
  end

  test "should update Attendance record" do
    visit attendance_record_url(@attendance_record)
    click_on "Edit this attendance record", match: :first

    fill_in "Date", with: @attendance_record.date
    check "Is present" if @attendance_record.is_present
    fill_in "Member", with: @attendance_record.member_id
    click_on "Update Attendance record"

    assert_text "Attendance record was successfully updated"
    click_on "Back"
  end

  test "should destroy Attendance record" do
    visit attendance_record_url(@attendance_record)
    click_on "Destroy this attendance record", match: :first

    assert_text "Attendance record was successfully destroyed"
  end
end
