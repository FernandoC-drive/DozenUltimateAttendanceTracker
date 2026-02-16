class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :player, null: false, foreign_key: { to_table: :users }
      t.date :date, null: false
      t.decimal :hours, precision: 6, scale: 2, null: false, default: 0
      t.boolean :attended, null: false, default: false
      t.integer :source, null: false, default: 0
      t.string :external_id
      t.text :notes
      t.boolean :override_by_leadership, null: false, default: false

      t.timestamps
    end

    add_index :attendances, [:player_id, :date], unique: true
    add_index :attendances, :external_id
  end
end
