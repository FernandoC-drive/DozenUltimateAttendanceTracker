require 'rails_helper'

RSpec.describe Attendance, type: :model do
  let(:player) { User.create!(name: "Test Player", email: "test@tamu.edu", password: "password") }

  describe "validations" do

    it "requires days_attended to be a non-negative integer" do
      attendance = Attendance.new(player: player, date: Date.current, days_attended: -1)
      attendance.valid?
      expect(attendance.errors[:days_attended]).to include("must be greater than or equal to 0")

      attendance.days_attended = 1.5
      attendance.valid?
      expect(attendance.errors[:days_attended]).to include("must be an integer")
    end
    
    it "is valid with a date and player" do
      attendance = Attendance.new(player: player, date: Date.current, days_attended: 1)
      expect(attendance).to be_valid
    end

    it "is invalid without a date" do
      attendance = Attendance.new(date: nil)
      expect(attendance).not_to be_valid
    end

    it "prevents a player from having two records on the same day" do
      Attendance.create!(player: player, date: Date.current, days_attended: 1)
      duplicate = Attendance.new(player: player, date: Date.current, days_attended: 2)
      expect(duplicate).not_to be_valid
    end

    it "fails if days are negative" do
      attendance = Attendance.new(player: player, date: Date.current, days_attended: -1)
      expect(attendance).not_to be_valid
    end
  end

  describe "#heat_level" do
    it "returns 0 when days_attended is 0" do
      attendance = Attendance.new(days_attended: 0)
      expect(attendance.heat_level).to eq(0)
    end

    it "returns 1 when days_attended is positive" do
      attendance = Attendance.new(days_attended: 1)
      expect(attendance.heat_level).to eq(1)
    end
  end

  describe "scopes" do
    let(:player) { User.create!(name: "Test", email: "test@tamu.edu", password: "password") }
    
    it "filters by day, week, and month" do
      today = Date.current
      attendance = Attendance.create!(player: player, date: today, days_attended: 1)
      
      expect(Attendance.for_day(today)).to include(attendance)
      expect(Attendance.for_week(today)).to include(attendance)
      expect(Attendance.for_month(today)).to include(attendance)
    end
  end

  describe ".monthly_percent_for" do
    let(:player) { User.create!(name: "PercentUser", email: "percent@tamu.edu", password: "password") }
    let(:base_date) { Date.new(2026, 2, 1) }

    it "returns 0.0 when there are no attendances" do
      expect(Attendance.monthly_percent_for(player, base_date)).to eq(0.0)
    end

    it "calculates the correct percentage" do
      # february 2026 has 28 days
      # we'll mark 14 days attended
      (1..14).each do |d|
        Attendance.create!(player: player, date: base_date.change(day: d), attended: true, days_attended: 1)
      end
      expect(Attendance.monthly_percent_for(player, base_date)).to eq(50.0)
    end

    it "rounds to one decimal place" do
      # create 1 out of 3-day month artificially by using march (31 days) but only 1 record
      date = Date.new(2026, 3, 1)
      Attendance.create!(player: player, date: date, attended: true, days_attended: 1)
      expected = (1.0 / 31 * 100).round(1)
      expect(Attendance.monthly_percent_for(player, date)).to eq(expected)
    end
  end

end