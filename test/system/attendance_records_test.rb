require "application_system_test_case"

class AttendanceRecordsTest < ApplicationSystemTestCase
  setup do
    @attendance_record = attendance_records(:one)
  end

  test "visiting the index" do
    visit attendance_records_url
    assert_selector "h1", text: "Attendance records"
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
