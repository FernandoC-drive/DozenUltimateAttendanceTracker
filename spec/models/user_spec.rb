require 'rails_helper'

RSpec.describe User, type: :model do
  describe ".from_google" do
    let(:google_data) do
      {
        email: 'fernando@tamu.edu',
        full_name: 'Fernando Cifuentes',
        uid: '12345',
        avatar_url: 'http://example.com/avatar.png'
      }
    end

    it "creates a new user if one does not exist" do
      expect {
        User.from_google(**google_data)
      }.to change(User, :count).by(1)
    end

    it "sets a random password for new Google users" do
      user = User.from_google(**google_data)
      expect(user.password_digest).to be_present
    end

    it "finds an existing user by email instead of creating a duplicate" do
      User.create!(email: 'fernando@tamu.edu', name: 'Fernando', password: 'password123')
      expect {
        User.from_google(**google_data)
      }.not_to change(User, :count)
    end
  end
end