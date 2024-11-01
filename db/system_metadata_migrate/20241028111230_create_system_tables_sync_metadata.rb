class CreateSystemTablesSyncMetadata < ActiveRecord::Migration[7.1]
  def change
    create_table 'system_tables_sync_metadata', if_not_exists: true do |t|
      t.string :table_name
      t.timestamp :last_sync_time

      t.timestamps
    end
  end
end
