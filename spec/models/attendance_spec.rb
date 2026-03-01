require 'rails_helper'

RSpec.describe Attendance, type: :model do
  # Set up a default player for the tests
  let(:player) { User.create!(name: "Test Player", email: "test@tamu.edu", password: "password", role: 0) }

  describe "Sunny Day Cases (Happy Path)" do
    
    it "is valid with a player, a date, and an attended status" do
      attendance = Attendance.new(player: player, date: Date.current, attended: true)
      expect(attendance).to be_valid
    end

    it "defaults to attended: false if not explicitly set" do
      attendance = Attendance.new(player: player, date: Date.current)
      expect(attendance).to be_valid
      expect(attendance.attended).to be(false).or be_nil
    end

    describe "scopes" do
      it "successfully filters records by day, week, and month" do
        today = Date.current
        attendance = Attendance.create!(player: player, date: today, attended: true)
        
        expect(Attendance.for_day(today)).to include(attendance)
        expect(Attendance.for_week(today)).to include(attendance)
        expect(Attendance.for_month(today)).to include(attendance)
      end
    end

    describe "#heat_level" do
      it "returns 0 if the player was marked absent" do
        attendance = Attendance.new(player: player, date: Date.current, attended: false)
        expect(attendance.heat_level).to eq(0)
      end

      it "returns 1 for low monthly attendance (1-4 days)" do
        attendance = Attendance.create!(player: player, date: Date.current, attended: true)
        expect(attendance.heat_level).to eq(1)
      end

      it "returns 4 for excellent monthly attendance (12+ days)" do
        # Simulate a highly active player by creating 11 past attendances
        11.times do |i|
          Attendance.create!(player: player, date: Date.current.beginning_of_month + i.days, attended: true)
        end
        
        # Create the 12th attendance record
        attendance = Attendance.create!(player: player, date: Date.current.end_of_month, attended: true)
        
        expect(attendance.heat_level).to eq(4)
      end
    end
  end

  describe "Rainy Day Cases (Error Handling)" do
    
    it "is invalid without a player" do
      attendance = Attendance.new(date: Date.current, attended: true)
      expect(attendance).not_to be_valid
      expect(attendance.errors[:player]).to include("must exist")
    end

    it "is invalid without a date" do
      attendance = Attendance.new(player: player, attended: true)
      expect(attendance).not_to be_valid
      expect(attendance.errors[:date]).to include("can't be blank")
    end

    it "prevents a player from having duplicate attendance records on the exact same day" do
      Attendance.create!(player: player, date: Date.current, attended: true)
      duplicate = Attendance.new(player: player, date: Date.current, attended: false)
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:date]).to include("has already been taken") 
    end
  end
end