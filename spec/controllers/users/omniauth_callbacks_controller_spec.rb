require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    # This mocks the data Google sends back to your app
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
  end
end