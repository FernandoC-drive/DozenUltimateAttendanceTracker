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

Attendance.find_or_create_by!(player: player, date: Date.current) do |a|
  a.hours = 1.5
  a.attended = true
  a.source = :manual
  a.notes = "Seed attendance"
end

RecsportsCredential.find_or_create_by!(form_url: "https://example.com/recsports_attendance.json") do |c|
  c.access_mode = :manual_upload
  c.active = true
end

puts "Seeded coach: #{coach.email} / password"
puts "Seeded player: #{player.email} / password"
