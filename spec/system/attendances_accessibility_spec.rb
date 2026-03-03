require "rails_helper"

RSpec.describe "Attendances accessibility", type: :system do
  before { driven_by(:rack_test) }

  let!(:player) do
    User.create!(
         name: "Alex Player",
         email: "alex_player@example.com",
         password: "password",
         role: :player,
         coach: false
    )
  end

  let!(:other_player) do
    User.create!(
         name: "Sam Other",
         email: "sam_other@example.com",
         password: "password",
         role: :player,
         coach: false
    )
  end

  before do
    Attendance.create!(player: player, date: Date.current.beginning_of_month, days_attended: 1, attended: true)
    Attendance.create!(player: other_player, date: Date.current.beginning_of_month + 1.day, days_attended: 0, attended: false)

    WorkoutCheckin.create!(player: player, workout_date: Date.current.beginning_of_month + 2.days, proof_url: "https://example.com/proof.png")
    WorkoutCheckin.create!(player: player, workout_date: Date.current.beginning_of_month + 3.days)

    sign_in(player)
  end

  it "shows color-blind-safe legend and explicit attendance statuses" do
    visit attendances_path

    expect(page).to have_css(".heat-legend", text: "Heatmap legend")
    expect(page).to have_css(".legend-item", text: "No attendance recorded")
    expect(page).to have_css(".legend-item", text: "Attendance recorded")

    expect(page).to have_css(".status-pill.present", text: "Present")
    expect(page).to have_css(".status-pill.absent", text: "Absent")

    expect(page).to have_css("tr[title*='Present on']")
    expect(page).to have_css("tr[title*='Absent on']")
  end

  it "shows workout status with non-color cues" do
    visit attendances_path

    expect(page).to have_css(".status-pill.proof-uploaded", text: "Proof attached")
    expect(page).to have_css(".status-pill.proof-missing", text: "No proof")
  end

  it "lets users switch color profile from the dropdown" do
    visit attendances_path

    expect(page).to have_select("Color profile", selected: "Red-Green Friendly")

    select "Blue-Yellow Friendly", from: "Color profile"
    click_button "Apply"

    expect(page).to have_css(".attendance-visualization.palette-tritanopia_safe")
    expect(page).to have_select("Color profile", selected: "Blue-Yellow Friendly")
  end

  def sign_in(user)
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end
end
