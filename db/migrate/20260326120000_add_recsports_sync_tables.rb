class AddRecsportsSyncTables < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :recsports_uin, :string
    add_index :users, :recsports_uin, unique: true

    create_table :recsports_events do |t|
      t.string :title, null: false
      t.string :event_type
      t.string :venue
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :source_url, null: false
      t.string :external_id
      t.string :created_by_name
      t.string :created_by_email
      t.datetime :source_created_at
      t.datetime :synced_at, null: false
      t.timestamps
    end

    add_index :recsports_events, :source_url, unique: true
    add_index :recsports_events, :external_id

    create_table :recsports_event_participants do |t|
      t.references :recsports_event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :recsports_uin
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :recsports_event_participants, %i[recsports_event_id user_id], unique: true, name: "index_recsports_participants_on_event_and_user"
    add_index :recsports_event_participants, %i[recsports_event_id recsports_uin], name: "index_recsports_participants_on_event_and_uin"
  end
end
