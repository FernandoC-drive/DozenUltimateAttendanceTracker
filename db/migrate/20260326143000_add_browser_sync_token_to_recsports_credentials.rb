class AddBrowserSyncTokenToRecsportsCredentials < ActiveRecord::Migration[8.0]
  def change
    add_column :recsports_credentials, :browser_sync_token, :string
    add_index :recsports_credentials, :browser_sync_token, unique: true
  end
end
