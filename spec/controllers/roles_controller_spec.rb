require 'rails_helper'

RSpec.describe RolesController, type: :controller do
  let(:user) { User.create!(email: 'tester@tamu.edu', name: 'Tester', password: 'password', coach: false) }

  before do
    session[:user_id] = user.id
  end

  describe "POST #enable_coach" do
    it "sets coach to true with the correct PIN" do
      post :enable_coach, params: { password: "gigem2027" }
      user.reload
      expect(user.coach).to be true
      expect(flash[:notice]).to eq("Coach view enabled.")
    end

    it "keeps coach false with an incorrect PIN" do
      post :enable_coach, params: { password: "wrong" }
      user.reload
      expect(user.coach).to be false
      expect(flash[:alert]).to eq("Incorrect Coach PIN.")
    end
  end

  describe "DELETE #disable_coach" do
    it "sets coach to false" do
      user.update(coach: true)
      delete :disable_coach
      user.reload
      expect(user.coach).to be false
    end
  end
end