class AddGoogleAndCoachToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :coach, :boolean, default: false
    add_column :users, :uid, :string
    add_column :users, :avatar_url, :string
  end
end
