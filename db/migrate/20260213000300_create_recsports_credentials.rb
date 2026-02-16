class CreateRecsportsCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :recsports_credentials do |t|
      t.integer :access_mode, null: false, default: 0
      t.string :form_url, null: false
      t.string :username
      t.string :password
      t.boolean :active, null: false, default: true
      t.datetime :last_checked_at
      t.text :last_error

      t.timestamps
    end
  end
end
