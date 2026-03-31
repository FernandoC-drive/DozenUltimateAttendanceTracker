require "rails_helper"

RSpec.describe "Attendances accessibility", type: :system do
  before { driven_by(:rack_test) }

  let!(:player) do
    User.create!(
         name: "Alex Player",
         email: "alex_player@tamu.edu",
         password: "password",
         role: :player
    )
  end

  let!(:other_player) do
    User.create!(
         name: "Sam Other",
         email: "sam_other@tamu.edu",
         password: "password",
         role: :player
    )
  end

  before do
    TeamSetting.current.update!(practice_days: [0, 1, 2, 3, 4, 5, 6])
    
    Attendance.create!(player: player, date: Date.current.beginning_of_month, days_attended: 1, attended: true)
    Attendance.create!(player: player, date: Date.current.beginning_of_month + 1.day, days_attended: 0, attended: false)

    WorkoutCheckin.create!(player: player, workout_date: Date.current.beginning_of_month + 2.days, proof_url: "https://example.com/proof.png")
    WorkoutCheckin.create!(player: player, workout_date: Date.current.beginning_of_month + 3.days)

    sign_in(player)
  end

  it "shows color-blind-safe legend and explicit attendance statuses" do
    visit attendances_path

    expect(page).to have_css(".heat-legend", text: "Heatmap legend")
    expect(page).to have_css(".legend-item", text: "0% attendance")
    expect(page).to have_css(".legend-item", text: "1-24% attendance")

    expect(page).to have_css(".status-pill.present", text: "Present")
    expect(page).to have_css(".status-pill.absent", text: "Absent")

    expect(page).to have_css("div[title*='Present on']")
    expect(page).to have_css("div[title*='Absent on']")
  end

  it "loads the correct CSS class for color profiles" do
    visit attendances_path(color_profile: "tritanopia_safe")
    expect(page).to have_css(".attendance-visualization.palette-tritanopia_safe")
  end

  def sign_in(user)
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end
end