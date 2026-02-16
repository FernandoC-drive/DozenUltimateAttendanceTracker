require 'rails_helper'

RSpec.describe Attendance, type: :model do
  let(:player) { User.create!(name: "Test Player", email: "test@tamu.edu", password: "password") }

  describe "validations" do

    it "is invalid if hours cannot be parsed as a number" do
      attendance = Attendance.new(player: player, date: Date.current, hours: "not-a-number")
      attendance.valid?
      expect(attendance.errors[:hours]).to include(Attendance::INVALID_HOURS_MESSAGE)
    end
    
    it "is valid with a date and player" do
      attendance = Attendance.new(player: player, date: Date.current, hours: 1.5)
      expect(attendance).to be_valid
    end

    it "is invalid without a date" do
      attendance = Attendance.new(date: nil)
      expect(attendance).not_to be_valid
    end

    it "prevents a player from having two records on the same day" do
      Attendance.create!(player: player, date: Date.current, hours: 1.0)
      duplicate = Attendance.new(player: player, date: Date.current, hours: 2.0)
      expect(duplicate).not_to be_valid
    end

    it "fails if hours are negative" do
      attendance = Attendance.new(player: player, date: Date.current, hours: -1)
      expect(attendance).not_to be_valid
    end
  end

  describe "#heat_level" do
    it "returns 0 for 0 hours" do
      attendance = Attendance.new(hours: 0)
      expect(attendance.heat_level).to eq(0)
    end

    it "returns 1 for small amounts of time" do
      attendance = Attendance.new(hours: 1.0)
      expect(attendance.heat_level).to eq(1)
    end

    it "returns 3 for 3+ hours" do
      attendance = Attendance.new(hours: 3.5)
      expect(attendance.heat_level).to eq(3)
    end
  end

  describe "scopes" do
    let(:player) { User.create!(name: "Test", email: "test@tamu.edu", password: "password") }
    
    it "filters by day, week, and month" do
      today = Date.current
      attendance = Attendance.create!(player: player, date: today, hours: 2)
      
      expect(Attendance.for_day(today)).to include(attendance)
      expect(Attendance.for_week(today)).to include(attendance)
      expect(Attendance.for_month(today)).to include(attendance)
    end
  end

end