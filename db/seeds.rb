# 1. Clean the database first (Order matters due to foreign keys!)
puts "Cleaning database..."
AttendanceRecord.destroy_all
WeeklyWorkout.destroy_all
Member.destroy_all

# 2. Create Members
puts "Creating Members..."
20.times do
  member = Member.create!(
    first_name: Faker::Name.first_name,
    last_name:  Faker::Name.last_name,
    email:      Faker::Internet.email,
    role:       [0, 1].sample # Randomly assign 0 (Member) or 1 (Leader)
  )

  # 3. Create 7 days of Attendance for this member
  (0..6).each do |days_ago|
    AttendanceRecord.create!(
      member: member,
      date: Date.today - days_ago.days,
      is_present: [true, false].sample
      # The is_excused line is gone!
    )
  end

  # 4. Create 4 weeks of Workouts for this member
  (0..3).each do |weeks_ago|
    WeeklyWorkout.create!(
      member: member,
      # Always sets the date to the Monday of that week
      week_start_date: (Date.today - weeks_ago.weeks).beginning_of_week,
      complete: [true, false].sample
    )
  end
end

puts "Done! Created 20 members with attendance and workout history."
