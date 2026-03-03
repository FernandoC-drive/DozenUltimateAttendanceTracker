class UpdateWeeklyWorkoutsToUsePlayers < ActiveRecord::Migration[8.0]
  def change
    remove_reference :weekly_workouts, :member, foreign_key: true

    add_reference :weekly_workouts, :player, null: false, foreign_key: { to_table: :users }

    add_index :weekly_workouts, %i[player_id week_start_date], unique: true
  end
end
