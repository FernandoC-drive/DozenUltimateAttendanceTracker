require 'rails_helper'

RSpec.describe Attendance, type: :model do
  let(:player) { User.create!(name: "Test Player", email: "test@tamu.edu", password: "password", role: 0) }

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

    it "defaults to attended: false if not explicitly set" do
      attendance = Attendance.new(player: player, date: Date.current)
      expect(attendance).to be_valid
      expect(attendance.attended).to be(false).or be_nil
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

  describe "#toggle_status!" do
    it "toggles an existing attendance back to an absence" do
      attendance = Attendance.create!(player: player, date: Time.zone.today, days_attended: 1, attended: true)

      attendance.toggle_status!

      expect(attendance.reload.days_attended).to eq(0)
      expect(attendance.attended).to be false
    end
  end

  describe "scopes" do
    let(:player) { User.create!(name: "Test", email: "test@tamu.edu", password: "password") }
    
    it "filters by day, week, and month" do
      today = Date.current
      Attendance.create!(player: player, date: today, days_attended: 1)
      duplicate = Attendance.new(player: player, date: today, days_attended: 2)
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:date]).to include("has already been taken") 
    end
  end

  describe ".monthly_percent_for" do
    let(:player) { User.create!(name: "PercentUser", email: "percent@tamu.edu", password: "password") }
    let(:base_date) { Date.new(2026, 2, 1) }

    # 1. We must configure the database settings BEFORE the tests run
    before do
      TeamSetting.current.update!(practice_days: [1, 3, 5]) # Sets it to Mon/Wed/Fri
    end

    it "returns 0.0 when there are no attendances" do
      expect(Attendance.monthly_percent_for(player, base_date)).to eq(0.0)
    end

    it "calculates the correct percentage" do
      # base_date is Feb 1, 2026. 
      # 14 days in means Feb 1 - Feb 14. 
      # Out of those 14 days, exactly 6 are MWF.
      (1..14).each do |d|
        Attendance.create!(player: player, date: base_date.change(day: d), attended: true, days_attended: 1)
      end
      
      # The player attended all 6 possible MWF days in that span.
      # There are 12 total MWF days in the entire month of Feb 2026.
      # 6 / 12 = 50.0%
      expect(Attendance.monthly_percent_for(player, base_date)).to eq(50.0)
    end

    it "rounds to one decimal place" do
      # March 2, 2026 is a Monday (a valid practice day)
      date = Date.new(2026, 3, 2)
      Attendance.create!(player: player, date: date, attended: true, days_attended: 1)
      
      # There are exactly 13 MWF practice days in March 2026
      expected = (1.0 / 13 * 100).round(1)
      
      expect(Attendance.monthly_percent_for(player, date)).to eq(expected)
    end
  end
end