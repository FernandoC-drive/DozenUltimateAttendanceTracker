require 'rails_helper'

RSpec.describe User, type: :model do
  describe ".from_google" do
    let(:google_data) do
      {
        email: 'aggie@tamu.edu',
        full_name: 'Test Aggie',
        uid: '111222333',
        avatar_url: 'http://example.com/pic.png'
      }
    end

    it "creates a new user with a random password if they don't exist" do
      expect {
        User.from_google(**google_data)
      }.to change(User, :count).by(1)
      
      new_user = User.last
      expect(new_user.name).to eq('Test Aggie')
      expect(new_user.uid).to eq('111222333')
      expect(new_user.password_digest).to be_present
    end

    it "finds an existing user and updates their Google info" do
      existing_user = User.create!(email: 'aggie@tamu.edu', name: 'Old Name', password: 'password123')
      
      expect {
        User.from_google(**google_data)
      }.not_to change(User, :count)
      
      existing_user.reload
      expect(existing_user.name).to eq('Test Aggie')
      expect(existing_user.uid).to eq('111222333')
    end
  end
end