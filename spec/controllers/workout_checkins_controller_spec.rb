require 'rails_helper'

RSpec.describe WorkoutCheckinsController, type: :controller do
  let(:player) { User.create!(name: "Test Player", email: "player@tamu.edu", password: "password", role: :player) }

  before do
    session[:user_id] = player.id
  end

  describe "POST #create" do
    it "saves a valid workout check-in using a proof URL" do
      post :create, params: { workout_checkin: { workout_date: Time.zone.today, proof_url: "https://example.com/proof.jpg" } }

      expect(WorkoutCheckin.count).to eq(1)
      expect(flash[:notice]).to eq("Workout check-in saved.")
      expect(response).to be_redirect
    end

    it "saves a valid workout check-in using an image upload" do
      tempfile = Tempfile.new(['dummy', '.jpg'])
      tempfile.write('dummy image data')
      tempfile.rewind
      uploaded_file = Rack::Test::UploadedFile.new(tempfile.path, 'image/jpeg')

      post :create, params: { workout_checkin: { workout_date: Time.zone.today, proof_image: uploaded_file } }

      expect(WorkoutCheckin.count).to eq(1)
      expect(flash[:notice]).to eq("Workout check-in saved.")
      expect(response).to be_redirect

      tempfile.close
      tempfile.unlink
    end

    it "redirects with an alert if the check-in is invalid" do
      post :create, params: { workout_checkin: { workout_date: nil } }

      expect(WorkoutCheckin.count).to eq(0)
      expect(flash[:alert]).to be_present
      expect(response).to redirect_to(attendances_path)
    end
  end

  describe "DELETE #destroy" do
    let!(:workout) { WorkoutCheckin.create!(player: player, workout_date: Time.zone.today, proof_url: "https://example.com/proof.jpg", source: 0) }

    it "deletes the workout check-in and redirects" do
      expect do
        delete :destroy, params: { id: workout.id }
      end.to change(WorkoutCheckin, :count).by(-1)

      expect(flash[:notice]).to be_present
      expect(response).to be_redirect
    end
  end

  describe "POST #create as a coach" do
    let(:coach) { User.create!(name: "Coach", email: "coach@tamu.edu", password: "password", role: :coach) }
    let(:other_player) { User.create!(name: "Other Player", email: "other@tamu.edu", password: "password", role: :player) }

    it "allows a coach to log a workout for a specific player" do
      session[:user_id] = coach.id
      post :create, params: { workout_checkin: { workout_date: Time.zone.today, proof_url: "https://example.com/proof.jpg", player_id: other_player.id } }

      expect(WorkoutCheckin.count).to eq(1)
      expect(WorkoutCheckin.first.player).to eq(other_player)
    end
  end

  describe "DELETE #destroy unauthorized" do
    let(:hacker) { User.create!(name: "Hacker", email: "hacker@tamu.edu", password: "password", role: :player) }
    let(:innocent_player) { User.create!(name: "Innocent", email: "innocent@tamu.edu", password: "password", role: :player) }
    let!(:workout) { WorkoutCheckin.create!(player: innocent_player, workout_date: Time.zone.today, proof_url: "https://example.com/proof.jpg", source: 0) }

    it "prevents a player from deleting someone else's workout" do
      session[:user_id] = hacker.id

      expect do
        delete :destroy, params: { id: workout.id }
      end.not_to change(WorkoutCheckin, :count)

      expect(flash[:alert]).to eq("Not authorized to delete this workout.")
      expect(response).to redirect_to(attendances_path)
    end
  end
end