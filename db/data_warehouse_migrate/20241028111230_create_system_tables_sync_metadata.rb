class CreateSystemTablesSyncMetadata < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up { execute 'CREATE SCHEMA IF NOT EXISTS admin_system_logs' }
      dir.down { execute 'DROP SCHEMA IF EXISTS admin_system_logs' }
    end

    execute <<-SQL
      CREATE TABLE IF NOT EXISTS admin_system_logs.system_tables_sync_metadata (
        table_name VARCHAR(255),
        last_sync_time TIMESTAMP
      );
    SQL
  end
end
