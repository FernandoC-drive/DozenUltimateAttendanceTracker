## 🚀 How to Run the App (Team Setup)

Follow these steps after you `git pull` the latest code to ensure your database and gems are up to date.

### 1. Start the Docker Container
Make sure you are in the project directory, then run the standard container command:

docker run -it --volume "$(PWD):/csce431" -e DATABASE_USER=test_app -e DATABASE_PASSWORD=test_password -p 3000:3000 paulinewade/csce431:sp26v1


### 2. Install New Gems
Update your bundle inside the container:

bundle install

### 3. Setup the Database
If this is your first time running this specific project, or if you want to reset your data to the clean "seed" state, run the setup command. It automatically creates the DB, migrates the schema, and populates it with 20 fake members.

bin/rails db:setup

### 4. Start the Server

bin/rails s -b 0.0.0.0
