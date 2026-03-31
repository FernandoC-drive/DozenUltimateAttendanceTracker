require 'rails_helper'

RSpec.describe RolesController, type: :controller do
  # Create a default player
  let(:user) { User.create!(name: "Test Player", email: "player@tamu.edu", password: "password", role: :player) }

  before do
    # Log the user in and set up a dummy "previous page" for redirect_back to use
    session[:user_id] = user.id
    request.env["HTTP_REFERER"] = root_path
  end

  describe "POST #enable_coach" do
    it "enables coach view when given the correct PIN" do
      post :enable_coach, params: { password: "howdy" }

      expect(user.reload.coach?).to be true
      expect(flash[:notice]).to eq("Coach view enabled.")
      expect(response).to redirect_to(root_path)
    end

    it "rejects the attempt when given an incorrect PIN" do
      post :enable_coach, params: { password: "wrong_pin" }

      expect(user.reload.coach?).to be false
      expect(flash[:alert]).to eq("Incorrect Coach PIN.")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST #disable_coach" do
    it "returns the user to the player view" do
      user.coach! # Force them to be a coach first

      post :disable_coach

      expect(user.reload.player?).to be true
      expect(flash[:notice]).to eq("Returned to Player view.")
      expect(response).to redirect_to(root_path)
    end
  end
end