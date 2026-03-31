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

    it "parses US-style recsports dates without swapping month and day" do
      snapshot = {
           "events" => [
                {
                     "title" => "Thursday Practice",
                     "starts_at" => "03/26/2026 8:00 PM",
                     "ends_at" => "03/26/2026 10:00 PM",
                     "source_url" => "https://sportclubs.example.com/events/789",
                     "participants" => [
                          { "first_name" => "Tony", "last_name" => "Cao", "uin" => "732004536", "position" => 0 }
                     ]
                }
           ]
      }

      described_class.new(snapshot: snapshot).call

      event = RecsportsEvent.find_by!(source_url: "https://sportclubs.example.com/events/789")
      attendance = Attendance.joins(:player).find_by!(users: { recsports_uin: "732004536" }, date: Date.new(2026, 3, 26))

      expect(event.event_date).to eq(Date.new(2026, 3, 26))
      expect(event.starts_at.hour).to eq(20)
      expect(attendance).to be_attended
    end

    it "removes stale recsports attendance when a re-sync corrects an event date" do
      user = User.create!(
           email: "tony@tamu.edu",
           name: "Tony Cao",
           password: "password",
           role: :player,
           recsports_uin: "732004536"
      )

      event = RecsportsEvent.create!(
           title: "Thursday Practice",
           starts_at: Time.zone.parse("2026-04-03 20:00"),
           ends_at: Time.zone.parse("2026-04-03 22:00"),
           source_url: "https://sportclubs.example.com/events/789",
           synced_at: Time.current
      )
      event.participants.create!(
           user: user,
           first_name: "Tony",
           last_name: "Cao",
           recsports_uin: "732004536",
           position: 0
      )
      Attendance.create!(
           player: user,
           date: Date.new(2026, 4, 3),
           days_attended: 1,
           attended: true,
           source: :recsports,
           notes: "Imported from RecSports events: Thursday Practice"
      )

      snapshot = {
           "events" => [
                {
                     "title" => "Thursday Practice",
                     "starts_at" => "03/26/2026 8:00 PM",
                     "ends_at" => "03/26/2026 10:00 PM",
                     "source_url" => "https://sportclubs.example.com/events/789",
                     "participants" => [
                          { "first_name" => "Tony", "last_name" => "Cao", "uin" => "732004536", "position" => 0 }
                     ]
                }
           ]
      }

      described_class.new(snapshot: snapshot).call

      expect(Attendance.find_by(player: user, date: Date.new(2026, 4, 3))).to be_nil
      expect(Attendance.find_by(player: user, date: Date.new(2026, 3, 26))).to be_present
      expect(event.reload.event_date).to eq(Date.new(2026, 3, 26))
    end
  end
end
