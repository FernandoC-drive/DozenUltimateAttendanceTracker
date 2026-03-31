class ChangeAttendancesHoursToDaysAttended < ActiveRecord::Migration[8.0]
  def up
    # add new column with default 0
    add_column :attendances, :days_attended, :integer, default: 0, null: false

    # backfill from existing data: if record was marked attended or had >0 hours, set days_attended = 1
    reversible do |dir|
      dir.up do
        say_with_time "Backfilling days_attended from hours/attended" do
          Attendance.reset_column_information
          Attendance.find_each do |a|
            value = a.attended || a.hours.to_f.positive? ? 1 : 0
            a.update_column(:days_attended, value)
          end
        end
      end
    end

    # remove hours column
    remove_column :attendances, :hours, :decimal
  end

  def down
    add_column :attendances, :hours, :decimal, precision: 6, scale: 2, default: "0.0", null: false
    Attendance.reset_column_information
    Attendance.find_each do |a|
      a.update_column(:hours, a.days_attended.to_f)
    end
    remove_column :attendances, :days_attended, :integer
  end
end