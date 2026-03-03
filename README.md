# Team Attendance App

## Local testing with Docker (recommended)

This repository ships with a `docker-compose.yml` that orchestrates both the
PostgreSQL database and the Rails application.  Using Compose avoids manual
network creation and container name conflicts.

1. From the project root, bring the stack up (this will build the web image if
   necessary, create the database, run migrations and seed the development
   data):

    ```powershell
    docker compose up --build
    ```

   The first run may take a minute while the gems are installed.  Once the
   rails server starts you can visit the app at `http://localhost:3000`.

2. When you're done, stop the services with `Ctrl+C` in the terminal or run:

    ```powershell
    docker compose down
    ```

3. If you ever need to run one‑off commands (tests, console, migrations) you
   can invoke the web service explicitly.  Because the service uses a `bash
   -lc` entrypoint, wrap your command in quotes and call it through Bundler so
   the Rails executable is available. For example:

    ```powershell
    docker compose run --rm web bash -lc "bundle exec rails test"
    docker compose run --rm web bash -lc "bundle exec rails db:reset db:seed"
    ```

   (substitute `rails console`, `rails db:migrate`, etc. as needed.)

4. (Optional) remove volumes to reset the database state:

    ```powershell
    docker compose down -v
    ```


Open the app in your browser at:

```
http://localhost:3000
```

## Test accounts

- Coach: `coach@example.com` / `password`
- Player: `player@example.com` / `password`

## UI enhancements

* **Attendance percentage bar**: displays the percentage of days attended during the selected month. Visible when a specific player has been selected.
* **Calendar view**: coaches (and players, when looking at another person) can switch the view to "Calendar" after choosing a player to see a month grid. Each day shows present/absent and coaches may click the toggle link to flip attendance for that day.

**Viewing permissions**

*Both players and coaches may now select any player from the dropdown. Leaving the selector blank shows everyone’s attendance; entering a name filters to that player. This allows players to inspect their teammates’ histories without needing coach privileges.*


## Manual acceptance checks

1. Sign in as coach.
2. Go to `Admin Attendance`, create/update attendance.
3. Confirm success flash: `Attendance updated successfully.`
4. Enter `-1` or `abc` for days attended and confirm you see a validation error.
5. Sign out and sign in as player.
6. Confirm updated days appear on player attendance page.

## Accessibility verification checks

1. Open `Attendance` and use the `Color profile` dropdown to switch between:
   `Standard`, `Red-Green Friendly`, `Blue-Yellow Friendly`, and
   `High Contrast Monochrome`.
2. Confirm the heatmap legend appears with:
   `No attendance recorded` and `Attendance recorded`.
3. Confirm attendance and workout statuses include text labels in addition to color:
   `Present`, `Absent`, `No data`, `Proof attached`, `No proof`.
4. Hover status chips/rows and confirm tooltip text appears.
5. Validate color-deficiency readability with a simulator/checker (for example,
   Chrome DevTools Rendering tab or Color Oracle) and verify statuses remain
   distinguishable via text/icon/pattern cues.

## Run automated tests

With the Docker Compose stack running (see above) you can execute the tests
from the `web` service:

```powershell
docker compose run --rm web rails test
```

This will spin up a temporary container, install any missing gems and run the
Rails test suite against the development database.


## Cleanup

Stop and remove the containers (and optionally volumes) with Docker Compose:

```powershell
docker compose down
# remove volumes too:
docker compose down -v
```
