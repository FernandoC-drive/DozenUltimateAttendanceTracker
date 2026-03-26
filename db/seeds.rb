puts "Cleaning up old records..."
WorkoutCheckin.destroy_all
WeeklyWorkout.destroy_all
Attendance.destroy_all
User.where(uid: nil).destroy_all

puts "Seeding fixed accounts..."

coach = User.find_or_create_by!(email: "coach@example.com") do |u|
  u.name = "Default Coach"
  u.role = :coach
  u.password = "password"
end

player = User.find_or_create_by!(email: "player@example.com") do |u|
  u.name = "Default Player"
  u.role = :player
  u.password = "password"
end

puts "Generating 10 random players with history..."
10.times do
  new_player = User.create!(
    name: Faker::Name.name,
    email: Faker::Internet.unique.email,
    password: "password123",
    role: :player
  )
  
  # Generate random dates within the last 30 days, but only Monday, Wednesday, Friday
  all_dates = (0..30).to_a.map { |d| d.days.ago.to_date }
  mwf_dates = all_dates.select { |date| [1, 3, 5].include?(date.wday) } # Monday=1, Wednesday=3, Friday=5
  unique_attendance_dates = mwf_dates.sample(5)

  unique_attendance_dates.each do |rand_date|
    attended_flag = [true, false].sample
    Attendance.create!(
      player_id: new_player.id,
      date: rand_date,
      days_attended: attended_flag ? 1 : 0,
      attended: attended_flag,
      source: 0
    )
  end
  
  unique_workout_offsets = (0..30).to_a.sample(rand(1..3))
  unique_workout_dates = unique_workout_offsets.map { |d| d.days.ago.to_date }

  unique_workout_dates.each do |rand_workout_date|
    WorkoutCheckin.create!(
      player_id: new_player.id,
      workout_date: rand_workout_date,
      proof_url: "https://example.com/fake_proof_#{rand(100..999)}.jpg",
      source: 0
    )
  end
end

RecsportsCredential.find_or_create_by!(form_url: "https://example.com/recsports_attendance.json") do |c|
  c.access_mode = 0
  c.active = true
end

puts "✅ Seeds completed!"
puts "Login: coach@example.com / password"