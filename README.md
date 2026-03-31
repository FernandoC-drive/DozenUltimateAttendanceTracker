# Dozen Ultimate Attendance Tracker

Dozen Ultimate Attendance Tracker is a Ruby on Rails app for managing team practice attendance, player workout submissions, and imported RecSports event rosters in one place.

It is designed around two user experiences:

- Players can sign in, review their own attendance, and submit workout proof.
- Coaches can review the whole team, adjust attendance records, set required practice days, and import event participation from RecSports.

## What the app does

The app combines three related pieces of team management:

- Attendance tracking for required practice days
- Workout logging with proof links or image uploads
- RecSports roster import so coaches can compare official event participation with internal attendance records

The main dashboard is also built to support multiple ways of viewing attendance:

- Calendar view for a visual monthly breakdown
- Monthly summary view
- Weekly summary view
- Daily summary view

## User roles

### Player

Players can:

- Sign in with email/password or Google
- View their own attendance history
- See monthly attendance progress
- Log workouts
- Upload workout proof by URL or image
- Delete their own workout submissions

### Coach

Coaches can:

- See team-wide attendance data
- Filter down to any individual player
- Toggle attendance directly from the calendar
- Override attendance records manually
- Mark weekly workout completion on behalf of a player
- Configure which weekdays count as required practice days
- Open the RecSports sync page and import event rosters

## Signing in

The app supports two sign-in paths:

- Local email/password login
- Google OAuth login for `@tamu.edu` accounts

Seeded local test accounts:

- Coach: `coach@tamu.edu` / `password`
- Player: `player@tamu.edu` / `password`

Google sign-in creates or updates a user based on their TAMU email. Coach access through Google is controlled by the `COACH_EMAILS` environment variable.

## Navigation overview

After signing in, the top navigation includes:

- `Dashboard`
- `Admin Settings` for coaches
- `RecSports Sync` for coaches
- `Sign out`

If a user is currently a player, the header also shows a `Coach PIN` field. Entering the correct PIN switches the user into coach mode for access to coach-only tools.

## Main pages

### 1. Sign In page

Path: `/session/new`

This is the entry point for the app. Users can:

- Sign in with email and password
- Sign in with Google

### 2. Dashboard

Path: `/`

This is the main page of the application and the page most users will spend the most time on.

The dashboard includes:

- Date navigation to move between days, weeks, or months
- A player filter
- Sort controls for team summaries
- View mode toggles
- Color profile toggles for accessibility
- Imported practice rosters
- A workout tracker section when an individual player is selected

#### Dashboard filters and controls

Users can change:

- The date period being viewed
- The selected player
- The sort order for team rankings
- The view mode: `Calendar`, `Monthly`, `Weekly`, or `Daily`
- The color palette used in the attendance heatmap

#### Calendar view

Calendar view is the most visual view in the app.

When a specific player is selected, the calendar shows each day as one of:

- `Present`
- `Absent`
- `No data`
- `Off Day`

When no player is selected, the calendar becomes a team heatmap and shows how many players attended on each date.

Coach-only action in this view:

- `Toggle` can flip a selected player from present to absent or absent to present for a day

#### Monthly, weekly, and daily summary views

These views show table-based attendance summaries instead of the month grid.

For each player, the table shows:

- Player name
- Days attended
- Total possible practice days
- Attendance percentage
- Workout completion status for the relevant week

Clicking a player name opens that player in detailed calendar view.

#### Imported Practice Rosters

This section appears on the dashboard below attendance.

It shows the most recently imported RecSports events, including:

- Event title
- Date and time
- Venue
- Participant count
- Imported participant names

This gives coaches and players a quick way to see whether external event data has been pulled into the system.

#### Workout Tracker

When a player is selected, the dashboard also shows that player's workout history.

Players can submit:

- A workout date
- A proof URL
- An uploaded image as proof

The tracker organizes workouts by week and month. Players can move backward and forward through months to review previous submissions.

Weekly workout completion is considered complete when a player logs at least two workouts during that week. Coaches can manually override that completion status from the attendance summary table.

If a coach marks a week's workout status as incomplete, that week's logged workouts are still visible but shown as rejected.

## Coach pages

### 3. Admin Settings

Path: `/admin/attendances`

This page is for coaches only.

It contains three main tools:

- `Player Quick Jump`
- `Team Practice Days`
- `Advanced Record Override`

#### Player Quick Jump

This search box lets a coach quickly jump straight to a player's dashboard calendar.

#### Team Practice Days

This controls which weekdays count toward required attendance calculations.

By default, the app uses:

- Monday
- Wednesday
- Friday

Changing these settings affects:

- Attendance percentages
- Total possible days
- Calendar interpretation of practice days versus off days

#### Advanced Record Override

This lets a coach force-save an attendance record for a selected player and date.

Useful cases include:

- Excused absences
- Manual corrections
- Data cleanup after bad imports
- Adding notes to explain a decision

### 4. RecSports Sync

Path: `/admin/recsports`

This page is also coach-only.

It manages the connection between the app and TAMU Sport Clubs / RecSports data.

The page includes:

- RecSports access settings
- A `Test access` button
- A `Sync now` form for manual payloads
- Chrome extension download instructions
- A browser sync token
- A table of latest imported events

#### RecSports access modes

The app supports multiple access modes, but the most important one for TAMU login flows is `Browser assisted`.

Use browser-assisted mode when RecSports requires:

- Microsoft sign-in
- Duo
- An authenticated browser session

#### Chrome extension sync flow

The intended browser-assisted sync process is:

1. Sign in as a coach.
2. Open `RecSports Sync`.
3. Set the access mode to `Browser assisted`.
4. Enter the Sport Clubs `Home Events` URL.
5. Save settings.
6. Download the Chrome extension zip from the page.
7. Load the unpacked extension into Chrome.
8. Open an authenticated sports club page (https://sportclubs.tamu.edu/) in Chrome.
9. Paste the app URL and browser sync token into the extension popup or have it auto detect in the recsports sync page using the detect button.
10. Run `Sync Current Tab`.

The extension then:

- Follows each event `View` link
- Scrapes participant data
- Sends the imported roster snapshot back to the Rails app

Those imported events appear both on the RecSports page and on the dashboard under `Imported Practice Rosters`.

## Typical user flows

### Player flow

1. Sign in.
2. Open the dashboard.
3. Review your attendance calendar or monthly summary.
4. Log a workout with a date and proof.
5. Check your workout history for the month.
6. Sign out when finished.

### Coach flow

1. Sign in or switch into coach mode with the coach PIN.
2. Open the dashboard to review team attendance.
3. Filter by player or leave the player filter blank to see the whole team.
4. Use the calendar or summary views to inspect attendance.
5. Toggle attendance or override records where needed.
6. Open `Admin Settings` to adjust team practice days or force-save a record.
7. Open `RecSports Sync` to import official participation data.

## Accessibility features

The dashboard includes multiple color profiles so attendance data remains readable for more users.

Available palette options:

- `Standard`
- `Red-Green Friendly`
- `Blue-Yellow Friendly`
- `Monochrome`

The interface also uses explicit text labels like:

- `Present`
- `Absent`
- `No data`

This means the app does not rely on color alone to communicate attendance state.

## Data tracked by the app

At a high level, the app stores:

- Users
- Attendance records by player and date
- Workout check-ins by player and date
- Weekly workout completion summaries
- Team practice-day settings
- RecSports credentials
- Imported RecSports events and participants

## Local setup

### Quick start with Docker

From the project root:

```powershell
docker compose up --build
```

Then open:

`http://localhost:3000`

### Manual Docker path

1. Create a Docker network:

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

## Running tests

From the project root:

```powershell
bundle install
bundle exec rails db:prepare
bundle exec rspec
```

## Notes for maintainers

- The root route is the attendance dashboard.
- Coach-only tools live under `/admin`.
- Workout proof images use Active Storage.
- Seed data creates one coach, one player, and a larger sample player dataset for demo/testing.
