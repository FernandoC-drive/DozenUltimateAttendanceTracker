class CreateWorkoutCheckins < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_checkins do |t|
      t.references :player, null: false, foreign_key: { to_table: :users }
      t.date :workout_date, null: false
      t.string :proof_url
      t.integer :source, null: false, default: 0

      t.timestamps
    end

    add_index :workout_checkins, [:player_id, :workout_date], unique: true
  end
end
