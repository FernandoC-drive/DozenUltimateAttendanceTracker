# Dozen Ultimate Attendance Tracker

Dozen Ultimate Attendance Tracker is a Ruby on Rails app for managing team practice attendance, player workout submissions, and imported RecSports event rosters in one place.

It is designed around two user experiences:

- Players can sign in, review their own attendance, and submit workout proof.
- Coaches can review the whole team, adjust attendance records, set required practice days, and import event participation from RecSports.

## Table of Contents

- [1. Project Description](#1-project-description)
- [2. User Roles](#2-user-roles)
  - [2.1 Player](#21-player)
  - [2.2 Coach](#22-coach)
- [3. Signing In](#3-signing-in)
- [4. Navigation Overview](#4-navigation-overview)
- [5. Application Pages](#5-application-pages)
  - [5.1 General Pages](#51-general-pages)
  - [5.1.1 Sign In Page](#511-sign-in-page)
  - [5.1.2 Dashboard](#512-dashboard)
  - [5.1.2.1 Dashboard Filters and Controls](#5121-dashboard-filters-and-controls)
  - [5.1.2.2 Calendar View](#5122-calendar-view)
  - [5.1.2.3 Monthly, Weekly, and Daily Summary Views](#5123-monthly-weekly-and-daily-summary-views)
  - [5.1.2.4 Imported Practice Rosters](#5124-imported-practice-rosters)
  - [5.1.2.5 Workout Tracker](#5125-workout-tracker)
  - [5.2 Coach Pages](#52-coach-pages)
  - [5.2.1 Admin Settings](#521-admin-settings)
  - [5.2.1.1 Player Quick Jump](#5211-player-quick-jump)
  - [5.2.1.2 Team Practice Days](#5212-team-practice-days)
  - [5.2.1.3 Advanced Record Override](#5213-advanced-record-override)
  - [5.2.2 RecSports Sync](#522-recsports-sync)
  - [5.2.2.1 RecSports Access Modes](#5221-recsports-access-modes)
  - [5.2.2.2 Chrome Extension Sync Flow](#5222-chrome-extension-sync-flow)
- [6. Typical User Flows](#6-typical-user-flows)
  - [6.1 Player Flow](#61-player-flow)
  - [6.2 Coach Flow](#62-coach-flow)
- [7. Accessibility Features](#7-accessibility-features)
- [8. Data Tracked by the App](#8-data-tracked-by-the-app)
- [9. Current Data Model](#9-current-data-model)
- [10. External Dependencies](#10-external-dependencies)
- [11. Environment Variables](#11-environment-variables)
- [12. Local Setup](#12-local-setup)
  - [12.1 Quick Start With Docker](#121-quick-start-with-docker)
  - [12.2 Manual Docker Path](#122-manual-docker-path)
- [13. Running Tests](#13-running-tests)
- [14. Notes for Maintainers](#14-notes-for-maintainers)
- [15. Credits](#15-credits)

## 1. Project Description

The app combines three related pieces of team management:

- Attendance tracking for required practice days
- Workout logging with proof links or image uploads
- RecSports roster import so coaches can compare official event participation with internal attendance records

The main dashboard is also built to support multiple ways of viewing attendance:

- Calendar view for a visual monthly breakdown
- Monthly summary view
- Weekly summary view
- Daily summary view

## 2. User Roles

### 2.1 Player

Players can:

- Sign in with email/password or Google
- View their own attendance history
- See monthly attendance progress
- Log workouts
- Upload workout proof by URL or image
- Delete their own workout submissions

### 2.2 Coach

Coaches can:

- See team-wide attendance data
- Filter down to any individual player
- Toggle attendance directly from the calendar
- Override attendance records manually
- Mark weekly workout completion on behalf of a player
- Configure which weekdays count as required practice days
- Open the RecSports sync page and import event rosters

## 3. Signing In

The app supports two sign-in paths:

- Local email/password login
- Google OAuth login for `@tamu.edu` accounts

Seeded local test accounts:

- Coach: `coach@tamu.edu` / `password`
- Player: `player@tamu.edu` / `password`

Google sign-in creates or updates a user based on their TAMU email. Coach access through Google is controlled by the `COACH_EMAILS` environment variable.

## 4. Navigation Overview

After signing in, the top navigation includes:

- `Dashboard`
- `Admin Settings` for coaches
- `RecSports Sync` for coaches
- `Sign out`

If a user is currently a player, the header also shows a `Coach PIN` field. Entering the correct PIN switches the user into coach mode for access to coach-only tools.

## 5. Application Pages

The main app experience is split between general pages used by all signed-in users and coach-only pages for team management.

### 5.1 General Pages

#### 5.1.1 Sign In Page

Path: `/session/new`

This is the entry point for the app. Users can:

- Sign in with email and password
- Sign in with Google

#### 5.1.2 Dashboard

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

##### 5.1.2.1 Dashboard Filters and Controls

Users can change:

- The date period being viewed
- The selected player
- The sort order for team rankings
- The view mode: `Calendar`, `Monthly`, `Weekly`, or `Daily`
- The color palette used in the attendance heatmap

##### 5.1.2.2 Calendar View

Calendar view is the most visual view in the app.

When a specific player is selected, the calendar shows each day as one of:

- `Present`
- `Absent`
- `No data`
- `Off Day`

When no player is selected, the calendar becomes a team heatmap and shows how many players attended on each date.

Coach-only action in this view:

- `Toggle` can flip a selected player from present to absent or absent to present for a day

##### 5.1.2.3 Monthly, Weekly, and Daily Summary Views

These views show table-based attendance summaries instead of the month grid.

For each player, the table shows:

- Player name
- Days attended
- Total possible practice days
- Attendance percentage
- Workout completion status for the relevant week

Clicking a player name opens that player in detailed calendar view.

##### 5.1.2.4 Imported Practice Rosters

This section appears on the dashboard below attendance.

It shows the most recently imported RecSports events, including:

- Event title
- Date and time
- Venue
- Participant count
- Imported participant names

This gives coaches and players a quick way to see whether external event data has been pulled into the system.

##### 5.1.2.5 Workout Tracker

When a player is selected, the dashboard also shows that player's workout history.

Players can submit:

- A workout date
- A proof URL
- An uploaded image as proof

The tracker organizes workouts by week and month. Players can move backward and forward through months to review previous submissions.

Weekly workout completion is considered complete when a player logs at least two workouts during that week. Coaches can manually override that completion status from the attendance summary table.

If a coach marks a week's workout status as incomplete, that week's logged workouts are still visible but shown as rejected.

### 5.2 Coach Pages

#### 5.2.1 Admin Settings

Path: `/admin/attendances`

This page is for coaches only.

It contains three main tools:

- `Player Quick Jump`
- `Team Practice Days`
- `Advanced Record Override`

##### 5.2.1.1 Player Quick Jump

This search box lets a coach quickly jump straight to a player's dashboard calendar.

##### 5.2.1.2 Team Practice Days

This controls which weekdays count toward required attendance calculations.

By default, the app uses:

- Monday
- Wednesday
- Friday

Changing these settings affects:

- Attendance percentages
- Total possible days
- Calendar interpretation of practice days versus off days

##### 5.2.1.3 Advanced Record Override

This lets a coach force-save an attendance record for a selected player and date.

Useful cases include:

- Excused absences
- Manual corrections
- Data cleanup after bad imports
- Adding notes to explain a decision

#### 5.2.2 RecSports Sync

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

##### 5.2.2.1 RecSports Access Modes

The app supports multiple access modes, but the most important one for TAMU login flows is `Browser assisted`.

Use browser-assisted mode when RecSports requires:

- Microsoft sign-in
- Duo
- An authenticated browser session

##### 5.2.2.2 Chrome Extension Sync Flow

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

## 6. Typical User Flows

### 6.1 Player Flow

1. Sign in.
2. Open the dashboard.
3. Review your attendance calendar or monthly summary.
4. Log a workout with a date and proof.
5. Check your workout history for the month.
6. Sign out when finished.

### 6.2 Coach Flow

1. Sign in or switch into coach mode with the coach PIN.
2. Open the dashboard to review team attendance.
3. Filter by player or leave the player filter blank to see the whole team.
4. Use the calendar or summary views to inspect attendance.
5. Toggle attendance or override records where needed.
6. Open `Admin Settings` to adjust team practice days or force-save a record.
7. Open `RecSports Sync` to import official participation data.

## 7. Accessibility Features

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

## 8. Data Tracked by the App

At a high level, the app stores:

- Users
- Attendance records by player and date
- Workout check-ins by player and date
- Weekly workout completion summaries
- Team practice-day settings
- RecSports credentials
- Imported RecSports events and participants

## 9. Current Data Model

The live database schema is centered on `users`, not `members`.

The main application flow uses:

- `users` for players and coaches
- `attendances` for per-player, per-day attendance
- `workout_checkins` for submitted workouts
- `weekly_workouts` for weekly completion overrides and summaries
- `team_settings` for required practice days
- `recsports_credentials`, `recsports_events`, and `recsports_event_participants` for RecSports sync

The schema also still contains older or secondary tables:

- `members` and `attendance_records` are legacy tables from an earlier design
- `admins` exists in the database but is not part of the main current app flow
- `active_storage_*` tables support workout proof image uploads

```mermaid
erDiagram
    USERS {
        bigint id PK
        string name
        string email UK
        integer role
        string password_digest
        string uid
        string avatar_url
        string recsports_uin UK
        datetime created_at
        datetime updated_at
    }

    ATTENDANCES {
        bigint id PK
        bigint player_id FK
        date date
        boolean attended
        integer source
        string external_id
        text notes
        boolean override_by_leadership
        integer days_attended
        datetime created_at
        datetime updated_at
    }

    WORKOUT_CHECKINS {
        bigint id PK
        bigint player_id FK
        date workout_date
        string proof_url
        integer source
        datetime created_at
        datetime updated_at
    }

    WEEKLY_WORKOUTS {
        bigint id PK
        bigint player_id FK
        date week_start_date
        boolean complete
        datetime created_at
        datetime updated_at
    }

    TEAM_SETTINGS {
        bigint id PK
        string practice_days
        datetime created_at
        datetime updated_at
    }

    RECSPORTS_CREDENTIALS {
        bigint id PK
        integer access_mode
        string form_url
        string username
        string password
        boolean active
        datetime last_checked_at
        text last_error
        string browser_sync_token UK
        datetime created_at
        datetime updated_at
    }

    RECSPORTS_EVENTS {
        bigint id PK
        string title
        string event_type
        string venue
        datetime starts_at
        datetime ends_at
        string source_url UK
        string external_id
        string created_by_name
        string created_by_email
        datetime source_created_at
        datetime synced_at
        datetime created_at
        datetime updated_at
    }

    RECSPORTS_EVENT_PARTICIPANTS {
        bigint id PK
        bigint recsports_event_id FK
        bigint user_id FK
        string first_name
        string last_name
        string recsports_uin
        integer position
        datetime created_at
        datetime updated_at
    }

    MEMBERS {
        bigint id PK
        string first_name
        string last_name
        string email
        integer role
        datetime created_at
        datetime updated_at
    }

    ATTENDANCE_RECORDS {
        bigint id PK
        bigint member_id FK
        date date
        boolean is_present
        datetime created_at
        datetime updated_at
    }

    ADMINS {
        bigint id PK
        string email UK
        string full_name
        string uid
        string avatar_url
        datetime created_at
        datetime updated_at
    }

    ACTIVE_STORAGE_BLOBS {
        bigint id PK
        string key UK
        string filename
        string content_type
        text metadata
        string service_name
        bigint byte_size
        string checksum
        datetime created_at
    }

    ACTIVE_STORAGE_ATTACHMENTS {
        bigint id PK
        string name
        string record_type
        bigint record_id
        bigint blob_id FK
        datetime created_at
    }

    USERS ||--o{ ATTENDANCES : "player_id"
    USERS ||--o{ WORKOUT_CHECKINS : "player_id"
    USERS ||--o{ WEEKLY_WORKOUTS : "player_id"
    USERS ||--o{ RECSPORTS_EVENT_PARTICIPANTS : "user_id"
    RECSPORTS_EVENTS ||--o{ RECSPORTS_EVENT_PARTICIPANTS : "recsports_event_id"
    MEMBERS ||--o{ ATTENDANCE_RECORDS : "member_id"
    ACTIVE_STORAGE_BLOBS ||--o{ ACTIVE_STORAGE_ATTACHMENTS : "blob_id"
```

Notes:

- `attendances` has a unique constraint on `player_id + date`
- `workout_checkins` has a unique constraint on `player_id + workout_date`
- `weekly_workouts` has a unique constraint on `player_id + week_start_date`
- `recsports_event_participants` has a unique constraint on `recsports_event_id + user_id`
- `team_settings` behaves like a singleton configuration table in application code
- Workout proof image uploads are polymorphic through Active Storage, so `active_storage_attachments.record_id` can point at `workout_checkins`

## 10. External Dependencies

The application depends on the following external software and services:

- Ruby 3.2 and Ruby on Rails 8.0.3
- PostgreSQL 16 for the application database
- Docker and Docker Compose for the recommended local setup
- The `paulinewade/csce431:sp26v1` Docker image used by the Rails web container
- Google OAuth through `omniauth-google-oauth2` for TAMU account sign-in
- TAMU Sport Clubs / RecSports event pages for imported roster data
- Chrome for the browser-assisted RecSports sync extension workflow
- Active Storage for uploaded workout proof images

Development and test dependencies are managed through `Gemfile` and include RSpec, Capybara, Selenium WebDriver, SimpleCov, RuboCop, Brakeman, and Dotenv.

## 11. Environment Variables

The app reads these environment variables during local development, testing, or deployment:

| Variable | Required? | Purpose |
| --- | --- | --- |
| `DATABASE_URL` | Required for production and manual Docker runs | Full PostgreSQL connection string. |
| `DATABASE_USER` | Optional | PostgreSQL username. Defaults to `postgres`. |
| `DATABASE_PASSWORD` | Optional | PostgreSQL password. Defaults to `postgres`. |
| `DATABASE_HOST` | Optional | PostgreSQL host. Defaults to `localhost`; Docker Compose uses `db`. |
| `DATABASE_PORT` | Optional | PostgreSQL port. Defaults to `5432`. |
| `DATABASE_NAME` | Optional | Development database name. Defaults to `d_uattendandance_development`. |
| `DATABASE_TEST_NAME` | Optional | Test database name. Defaults to `d_uattendandance_test`. |
| `RAILS_ENV` | Optional | Rails environment, such as `development`, `test`, or `production`. |
| `RAILS_MAX_THREADS` | Optional | Puma and database connection pool thread count. |
| `PORT` | Optional | Rails server port. Defaults to `3000`. |
| `GOOGLE_OAUTH_CLIENT_ID` | Required for Google sign-in | Google OAuth client ID for TAMU login. |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Required for Google sign-in | Google OAuth client secret for TAMU login. |
| `COACH_EMAILS` | Optional | Comma-separated TAMU emails that should receive coach access after Google sign-in. |
| `COACH_PIN` | Required for coach PIN switching | PIN entered from the header to switch a player session into coach mode. |
| `REDIS_URL` | Required for production Action Cable if Redis is used | Redis connection string. Defaults to `redis://localhost:6379/1` in production config. |
| `RAILS_MASTER_KEY` | Required for encrypted production credentials | Rails credentials key for production deployments that use encrypted credentials. |
| `SECRET_KEY_BASE` | Required for production | Rails secret key base for production runtime. |
| `RAILS_LOG_LEVEL` | Optional | Production log level. Defaults to `info`. |
| `SOLID_QUEUE_IN_PUMA` | Optional | Enables the Solid Queue supervisor inside Puma for single-server deployments. |
| `PIDFILE` | Optional | Custom Puma PID file path. |

Docker Compose sets the database-related variables for local development automatically. Google sign-in and coach PIN switching require the OAuth and coach access variables to be set separately.

## 12. Local Setup

### 12.1 Quick Start With Docker

From the project root:

```powershell
docker compose up --build
```

Then open:

`http://localhost:3000`

### 12.2 Manual Docker Path

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

## 13. Running Tests

From the project root:

```powershell
bundle install
bundle exec rails db:prepare
bundle exec rspec
```

## 14. Notes for Maintainers

- The root route is the attendance dashboard.
- Coach-only tools live under `/admin`.
- Workout proof images use Active Storage.
- Seed data creates one coach, one player, and a larger sample player dataset for demo/testing.

## 15. Credits

Project contributors include Fernando Cifuentes, Ethan Tong, Sam Huhn, and Sebastian Silva.

This application is built with Ruby on Rails, PostgreSQL, Hotwire, RSpec, Docker, Google OAuth, Active Storage, and a Chrome extension for browser-assisted RecSports imports.
