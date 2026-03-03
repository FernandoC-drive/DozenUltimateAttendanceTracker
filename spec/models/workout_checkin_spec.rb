require 'rails_helper'

RSpec.describe WorkoutCheckin, type: :model do
  # Set up a dummy user for the tests
  let(:player) { User.create!(name: "Test Player", email: "player@example.com", password: "password", role: 0) }

  describe "Sunny Day Cases (Happy Path)" do
    it "is valid with a player, date, and proof" do
      checkin = WorkoutCheckin.new(player: player, workout_date: Time.zone.today, proof_url: "https://example.com/image.jpg")
      expect(checkin).to be_valid
    end

    it "automatically completes the weekly workout requirement upon creation" do
      today = Time.zone.today

      # 1. Player submits a workout
      WorkoutCheckin.create!(player: player, workout_date: today, proof_url: "https://example.com/image.jpg")

      # 2. Check if the WeeklyWorkout record was created and marked complete
      weekly_workout = WeeklyWorkout.find_by(player: player, week_start_date: today.beginning_of_week)

      expect(weekly_workout).not_to be_nil
      expect(weekly_workout.complete).to be true
    end

    it "safely handles multiple check-ins in the same week without crashing" do
      monday = Time.zone.today.beginning_of_week
      tuesday = monday + 1.day

      # Player works out Monday
      WorkoutCheckin.create!(player: player, workout_date: monday)

      # Player works out Tuesday (should not crash the unique database index)
      expect do
        WorkoutCheckin.create!(player: player, workout_date: tuesday)
      end.not_to raise_error

      # Ensure there is still only ONE weekly record for this player
      expect(WeeklyWorkout.where(player: player, week_start_date: monday).count).to eq(1)
    end
  end

  describe "Rainy Day Cases (Error Handling)" do
    it "is invalid without a player" do
      checkin = WorkoutCheckin.new(workout_date: Time.zone.today)
      expect(checkin).not_to be_valid
      expect(checkin.errors[:player]).to include("must exist")
    end

    it "is invalid without a workout date" do
      checkin = WorkoutCheckin.new(player: player)
      expect(checkin).not_to be_valid
      expect(checkin.errors[:workout_date]).to include("can't be blank")
    end

    it "prevents duplicate check-ins on the exact same day" do
      # Submit the first workout
      WorkoutCheckin.create!(player: player, workout_date: Time.zone.today)

      # Try to submit a second one on the same day
      duplicate_checkin = WorkoutCheckin.new(player: player, workout_date: Time.zone.today)

      expect(duplicate_checkin).not_to be_valid
      expect(duplicate_checkin.errors[:workout_date]).to include("has already been logged")
    end
  end
end
