require 'rails_helper'

RSpec.describe "Admin Control Robustness", type: :system do
  before { driven_by(:rack_test) }
  let(:admin) { User.create!(name: "Admin Alice", role: :coach, email: "admin@tamu.edu", password: "password") }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
  end

  it "prevents the user from submitting the override form without selecting a player" do
    visit admin_attendances_path

    # Initial state
    initial_count = Attendance.count

    # User explicitly leaves the player dropdown blank and tries to force save
    fill_in "Optional notes...", with: "Forgot to select a player!"
    click_button "Force Save Record"

    # Verify the robust control worked: The database was protected from bad data
    expect(Attendance.count).to eq(initial_count)

    # Verify we are still on the same page (it didn't crash)
    expect(page).to have_content("Advanced Record Override")
  end
end