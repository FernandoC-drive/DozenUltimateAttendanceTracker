require 'rails_helper'

RSpec.describe "Dashboard Navigation Operability", type: :system do
  before { driven_by(:rack_test) }
  include ActiveSupport::Testing::TimeHelpers

  let(:coach) { User.create!(name: "Coach Bob", role: :coach, email: "coach@tamu.edu", password: "password") }
  let!(:player) { User.create!(name: "Gaston Orn", role: :player, email: "gaston@tamu.edu", password: "password") }

  before do
    # 1. Freeze time to a known, mathematically perfect month (March 2026)
    travel_to Date.new(2026, 3, 2)

    # 2. Set the practice days to MWF
    TeamSetting.current.update!(practice_days: [1, 3, 5])

    # 3. Create a guaranteed attendance record on exactly March 2nd (A Monday)
    Attendance.create!(player: player, date: Date.new(2026, 3, 2), attended: true, days_attended: 1)

    # Log in the coach using the actual UI
    visit new_session_path
    fill_in "Email", with: coach.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  after do
    travel_back
  end

  it "allows seamless drill-down navigation from the team summary to a specific player's calendar" do
    # 1. Force Capybara to load the Monthly summary tab on the exact month we seeded data!
    visit attendances_path(view: 'monthly', date: '2026-03-02')
    
    # 2. Safety Net: If Capybara STILL can't find the link, it will print the raw HTML 
    # to your terminal so you can instantly see if the table is hidden or empty!
    unless page.has_css?("a.player-name-link", text: player.name)
      puts "\n\n--- TERMINAL DEBUG: CAPYBARA HTML ---"
      puts page.html
      puts "-------------------------------------\n\n"
    end

    # 3. Use a robust CSS finder to click the specific class you added to the HTML
    find("a.player-name-link", text: player.name).click

    # 4. Verify it successfully drilled down to the calendar view for that specific player
    expect(page).to have_current_path(attendances_path(player_id: player.id, view: 'calendar', date: '2026-03-02'))
    
    expect(page).to have_content("#{player.name} attendance for")
  end
end