require 'rails_helper'

RSpec.describe "DashboardFlow", type: :system do
  before do
    driven_by(:rack_test)
    
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '987654321',
      info: { email: 'fernando@tamu.edu', name: 'Fernando Cifuentes' }
    })
  end

  it "allows a user to log in with Google, view the dashboard, and sign out" do
    # 1. Go to the login page
    visit new_session_path
    
    # 2. Click the Google login button (simulates the OAuth callback)
    # Note: Adjust the button text if yours differs slightly!
    click_button "Sign in with Google"
    
    # 3. Verify we made it to the dashboard
    expect(page).to have_content("Attendance")
    expect(page).to have_content("Successfully authenticated from Google account.")
    
    # 4. Interact with the filters
    select "Weekly", from: "view"
    click_button "Apply"
    expect(page).to have_content("Attendance")

    # 5. Sign out
    click_button "Sign out"
    expect(page).to have_content("Signed out")
  end
end