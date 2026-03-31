require 'rails_helper'

RSpec.describe Admin::AttendancesController, type: :controller do
  let(:coach) { User.create!(email: "coach@tamu.edu", name: "Coach", password: "password", role: :coach) }

  before do
    # 1. Log in the coach
    session[:user_id] = coach.id
    
    # 2. Mock the HTTP_REFERER so 'redirect_back' knows where to go
    request.env["HTTP_REFERER"] = admin_attendances_path 
  end

  describe "PATCH #update_settings" do
    it "updates the team practice days and redirects back" do
      # Simulate submitting the form with Mondays (1) and Wednesdays (3)
      patch :update_settings, params: { practice_days: ["1", "3"] }
      
      # Verify the database updated
      expect(TeamSetting.current.practice_days).to eq(["1", "3"])
      
      # Verify the fallback redirect and notice worked (This covers those red lines!)
      expect(flash[:notice]).to eq("Practice days updated successfully!")
      expect(response).to redirect_to(admin_attendances_path)
    end

    it "safely handles when all days are unchecked (nil params)" do
      patch :update_settings, params: { practice_days: nil }
      
      expect(TeamSetting.current.practice_days).to eq([])
      expect(response).to redirect_to(admin_attendances_path)
    end
  end
end