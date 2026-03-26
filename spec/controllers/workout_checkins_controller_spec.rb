require 'rails_helper'

RSpec.describe WorkoutCheckinsController, type: :controller do
  let(:player) { User.create!(name: "Test Player", email: "player@tamu.edu", password: "password", role: :player) }

  before do
    session[:user_id] = player.id
  end

  describe "POST #create" do
    it "saves a valid workout check-in" do
      post :create, params: { workout_checkin: { workout_date: Date.today, proof_url: "https://example.com/proof.jpg" } }
      
      expect(WorkoutCheckin.count).to eq(1)
      expect(flash[:notice]).to eq("Workout check-in saved.")
    end

    it "redirects with an alert if the check-in is invalid" do
      # Passing a nil date will cause the model validation to fail, triggering the 'else' block!
      post :create, params: { workout_checkin: { workout_date: nil } }
      
      expect(WorkoutCheckin.count).to eq(0)
      expect(flash[:alert]).to include("can't be blank")
      expect(response).to redirect_to(attendances_path)
    end
  end
end