class RemoveCoachFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :coach, :boolean
  end
end
