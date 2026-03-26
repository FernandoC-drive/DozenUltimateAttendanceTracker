require "rails_helper"

RSpec.describe Recsports::Importer do
  describe "#call" do
    it "creates events, participants, players, and aggregated attendance" do
      snapshot = {
        "events" => [
          {
            "title" => "Monday Practice",
            "starts_at" => "2025-08-25 20:00",
            "ends_at" => "2025-08-25 22:00",
            "source_url" => "https://sportclubs.example.com/events/123",
            "participants" => [
              { "first_name" => "Aldrich", "last_name" => "Leow", "uin" => "732005379", "position" => 0 },
              { "first_name" => "Alexander", "last_name" => "Vo", "uin" => "535009099", "position" => 1 }
            ]
          },
          {
            "title" => "Film Session",
            "starts_at" => "2025-08-25 18:00",
            "ends_at" => "2025-08-25 19:00",
            "source_url" => "https://sportclubs.example.com/events/456",
            "participants" => [
              { "first_name" => "Aldrich", "last_name" => "Leow", "uin" => "732005379", "position" => 0 }
            ]
          }
        ]
      }

      described_class.new(snapshot: snapshot).call

      expect(RecsportsEvent.count).to eq(2)
      expect(RecsportsEventParticipant.count).to eq(3)

      user = User.find_by(recsports_uin: "732005379")
      expect(user).to be_present
      expect(user.name).to eq("Aldrich Leow")

      attendance = Attendance.find_by(player: user, date: Date.new(2025, 8, 25))
      expect(attendance).to be_present
      expect(attendance.days_attended).to eq(2)
      expect(attendance).to be_attended
      expect(attendance.notes).to include("Monday Practice", "Film Session")
    end
  end
end
