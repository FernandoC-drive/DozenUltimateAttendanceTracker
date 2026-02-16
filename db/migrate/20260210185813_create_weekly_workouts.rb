class CreateWeeklyWorkouts < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_workouts do |t|
      t.references :member, null: false, foreign_key: true
      t.date :week_start_date
      t.boolean :complete

      t.timestamps
    end
  end
end
