class CreateAttendanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_records do |t|
      t.references :member, null: false, foreign_key: true
      t.date :date
      t.boolean :is_present

      t.timestamps
    end
  end
end
