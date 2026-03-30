require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET #google_oauth2" do
    it "creates a user and signs them in with a valid @tamu.edu email" do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '12345',
        info: { email: 'valid_user@tamu.edu', name: 'Valid User', image: 'avatar.png' }
      })
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]

      expect {
        get :google_oauth2
      }.to change(User, :count).by(1)
      
      expect(response).to redirect_to(root_path)
    end

    it "redirects to the login page with an alert if authentication fails (e.g. non-TAMU email)" do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '98765',
        info: { email: 'sneaky_user@gmail.com', name: 'Sneaky User', image: 'avatar.png' }
      })
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]

      expect {
        get :google_oauth2
      }.not_to change(User, :count)

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
end