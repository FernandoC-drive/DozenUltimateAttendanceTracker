require 'rails_helper'

RSpec.describe WorkoutCheckinsController, type: :controller do
  let(:player) { User.create!(email: 'athlete@tamu.edu', name: 'Athlete', password: 'password', coach: false) }

  before do
    session[:user_id] = player.id
  end

  describe "POST #create" do
    it "creates a new checkin and redirects to monthly view" do
      post :create, params: { workout_checkin: { workout_date: Date.current, proof_url: "http://example.com/proof.jpg" } }
      expect(WorkoutCheckin.count).to eq(1)
      expect(response).to redirect_to(attendances_path(view: "monthly", date: Date.current))
    end

    it "fails with invalid params and redirects back" do
      post :create, params: { workout_checkin: { workout_date: nil, proof_url: "http://example.com/proof.jpg" } }
      expect(WorkoutCheckin.count).to eq(0)
      expect(flash[:alert]).to be_present
      expect(response).to redirect_to(attendances_path)
    end
  end
end