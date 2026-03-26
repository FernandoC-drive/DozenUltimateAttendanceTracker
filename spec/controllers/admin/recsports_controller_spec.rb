require "rails_helper"

RSpec.describe Admin::RecsportsController, type: :controller do
  let(:coach) { User.create!(email: "coach@tamu.edu", name: "Coach", password: "password", role: :coach) }

  before do
    session[:user_id] = coach.id
  end

  describe "POST #sync_now" do
    it "runs the sync immediately and redirects with a success message" do
      RecsportsCredential.create!(
        form_url: "https://sportclubs.example.com/clubs/ultimate",
        username: "ethan",
        password: "secret",
        access_mode: :manual_upload
      )

      payload = {
        events: [
          {
            title: "Monday Practice",
            starts_at: "2025-08-25 20:00",
            source_url: "manual://practice-1",
            participants: [
              { first_name: "Aldrich", last_name: "Leow", uin: "732005379", position: 0 }
            ]
          }
        ]
      }.to_json

      post :sync_now, params: { manual_payload: payload }

      expect(response).to redirect_to(admin_recsports_path)
      expect(flash[:notice]).to eq("RecSports sync completed.")
      expect(RecsportsEvent.count).to eq(1)
      expect(User.find_by(recsports_uin: "732005379")).to be_present
    end
  end

  describe "POST #browser_sync" do
    it "imports a browser-assisted snapshot when the token is valid" do
      credential = RecsportsCredential.create!(
        form_url: "https://sportclubs.tamu.edu/home/userClubs",
        access_mode: :browser_assisted
      )

      payload = {
        events: [
          {
            title: "Wednesday Practice",
            starts_at: "2025-08-27 20:00",
            source_url: "https://sportclubs.tamu.edu/home/events/123",
            participants: [
              { first_name: "Alexander", last_name: "Vo", uin: "535009099", position: 0 }
            ]
          }
        ]
      }.to_json

      post :browser_sync, params: { token: credential.browser_sync_token, snapshot: payload }

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include("status" => "ok", "imported_events" => 1)
      expect(RecsportsEvent.find_by(title: "Wednesday Practice")).to be_present
      expect(User.find_by(recsports_uin: "535009099")).to be_present
    end

    it "rejects an invalid browser sync token" do
      post :browser_sync, params: { token: "bad-token", snapshot: {}.to_json }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to include("error" => "Invalid browser sync token.")
    end
  end
end
