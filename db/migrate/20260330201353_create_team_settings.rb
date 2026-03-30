class CreateTeamSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :team_settings do |t|
      t.string :practice_days, default: "[1, 3, 5]"

      t.timestamps
    end
  end
end