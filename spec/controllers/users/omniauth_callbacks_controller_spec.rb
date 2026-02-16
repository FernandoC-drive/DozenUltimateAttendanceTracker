require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '12345',
      info: { email: 'fernando@tamu.edu', name: 'Fernando Cifuentes' }
    })
  end

  describe "GET #google_oauth2" do
    it "creates a user and signs them in" do
      expect {
        get :google_oauth2
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(root_path)
    end

    describe "GET #google_oauth2 (Rainy Day)" do
    it "redirects to the login page with an alert if user creation fails" do
      allow(User).to receive(:from_google).and_return(nil) 
      
      get :google_oauth2
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Authentication failed.")
    end
  end

  describe "Protected Methods" do
    it "returns the new session path on failure" do
      path = controller.send(:after_omniauth_failure_path_for, :user)
      expect(path).to eq(new_session_path)
    end
  end

    context "when authentication fails" do
      it "redirects to the login page with an alert" do
        allow(User).to receive(:from_google).and_return(nil)
        
        get :google_oauth2
        
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("Authentication failed.")
      end
    end
  end
end