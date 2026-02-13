# Team Attendance App

## Local testing with Docker (recommended)

Run these commands from the project root in PowerShell.

1. Create a Docker network (one time):

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

3. Start Rails app:

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

- Coach: `coach@example.com` / `password`
- Player: `player@example.com` / `password`

## Manual acceptance checks

1. Sign in as coach.
2. Go to `Admin Attendance`, create/update attendance.
3. Confirm success flash: `Attendance updated successfully.`
4. Enter `-1` or `abc` for hours and confirm: `Invalid attendance hours.`
5. Sign out and sign in as player.
6. Confirm updated hours appear on player attendance page.

## Run automated tests

In a new terminal while Rails container is running:

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
