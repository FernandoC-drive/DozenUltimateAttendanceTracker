# Team Attendance App

## Local testing with Docker

Run these commands from the project root in PowerShell.

### Option 1: `docker compose`

This is the fastest local startup path.

```powershell
docker compose up --build
```

Then open:

`http://localhost:3000`

### Option 2: manual Docker commands

1. Create a Docker network one time:

```powershell
docker network create attendance-net
```

2. Start PostgreSQL:

```powershell
docker run -d --name attendance-db --network attendance-net `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=d_uattendandance_development `
  -p 5432:5432 postgres:16
```

3. Start Rails:

```powershell
docker run --rm -it --network attendance-net `
  -p 3000:3000 `
  -e DATABASE_URL=postgres://postgres:postgres@attendance-db:5432/d_uattendandance_development `
  -v ${PWD}:/app `
  --entrypoint /bin/bash paulinewade/csce431:sp26v1 `
  -lc "cd /app && sed -i 's/\r$//' bin/* && bundle install && bundle exec rails db:prepare db:seed && bundle exec rails server -b 0.0.0.0 -p 3000"
```

4. Open the app:

`http://localhost:3000`

## Test accounts

- Coach: `coach@tamu.com` / `password`
- Player: `player@tamu.com` / `password`

## RecSports sync setup

After the app is running:

1. Sign in as the coach user.
2. Open `RecSports Sync` from the top navigation.
3. Set `Club or Home Events URL` to:

```text
https://sportclubs.tamu.edu/home/userClubs
```

4. Set `Access mode` to `Browser assisted`.
5. Save the settings.
6. Copy the `Browser Sync Token` shown on the page.
7. Download the Chrome extension zip from the `RecSports Sync` page.
8. Unzip it locally and load the unpacked `recsports_chrome_extension` folder in Chrome.
9. In Chrome, sign in to TAMU Sport Clubs and open the authenticated `Home Events` page.
10. Open the extension popup.
11. Enter:
    - your attendance app URL
    - the browser sync token
12. Click `Sync Current Tab`.

What the sync does:

- runs inside the user's authenticated Chrome session
- discovers each `View` event page
- scrapes the participants table
- posts the imported snapshot back into the Rails app
- stores imported event rosters and attendance rows by event date

Imported rosters appear on the main attendance dashboard under `Imported Practice Rosters`.

## Manual acceptance checks

1. Sign in as coach.
2. Go to `Admin Attendance` and create or update an attendance row.
3. Confirm the success flash says `Attendance updated successfully.`
4. Enter `-1` or `abc` for attendance input and confirm validation blocks it.
5. Open `RecSports Sync`, configure browser-assisted mode, and save the settings.
6. Download the Chrome extension zip from the `RecSports Sync` page.
7. Unzip it locally and load the unpacked `recsports_chrome_extension` folder in Chrome.
8. Sign in to Sport Clubs, open Home Events, and run `Sync Current Tab` from the extension.
9. Return to the dashboard and confirm imported rosters appear.
10. Sign out and sign in as player.
11. Confirm attendance still appears correctly on the player dashboard.

## Accessibility verification checks

1. Open `Attendance` and use the `Color profile` dropdown to switch between `Standard`, `Red-Green Friendly`, `Blue-Yellow Friendly`, and `High Contrast Monochrome`.
2. Confirm the heatmap legend appears with `No attendance recorded` and `Attendance recorded`.
3. Confirm attendance and workout statuses include text labels in addition to color: `Present`, `Absent`, `No data`, `Proof attached`, `No proof`.
4. Hover status chips or rows and confirm tooltip text appears.
5. Validate readability with a color-deficiency simulator such as Chrome DevTools Rendering or Color Oracle.

## Run automated tests

From the project root:

```powershell
bundle install
bundle exec rails db:prepare
bundle exec rspec spec/services/recsports/client_spec.rb spec/services/recsports/importer_spec.rb spec/controllers/admin/recsports_controller_spec.rb spec/controllers/attendances_controller_spec.rb
```

Or, in a new terminal while the Rails container is running:

```powershell
docker run --rm -it --network attendance-net `
  -e DATABASE_URL=postgres://postgres:postgres@attendance-db:5432/d_uattendandance_development `
  -v ${PWD}:/app `
  --entrypoint /bin/bash paulinewade/csce431:sp26v1 `
  -lc "cd /app && sed -i 's/\r$//' bin/* && bundle install && bundle exec rails test"
```

## Cleanup

```powershell
docker stop attendance-db
docker rm attendance-db
docker network rm attendance-net
```
