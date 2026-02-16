require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { User.create!(email: 'test@tamu.edu', name: 'Tester', password: 'password') }

  describe "DELETE #destroy" do
    before do
      session[:user_id] = user.id
    end

    it "clears the session and redirects to login" do
      delete :destroy
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq("Signed out.")
    end
  end
end