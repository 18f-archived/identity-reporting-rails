class BackupEventsAndProductionTables < ActiveRecord::Migration[7.2]
  def up
    if connection.adapter_name.downcase.include?("redshift")
      # Create temporary tables

      execute 'CREATE TABLE IF NOT EXISTS logs.events_backup (LIKE logs.events);' 
      execute 'CREATE TABLE IF NOT EXISTS logs.production_backup (LIKE logs.production);'
      execute <<-SQL
        INSERT INTO logs.events_backup
        SELECT * FROM logs.events WHERE cloudwatch_timestamp >= CURRENT_DATE - INTERVAL '30 days';
      SQL

      execute <<-SQL
        INSERT INTO logs.production_backup
        SELECT * FROM logs.production WHERE cloudwatch_timestamp >= CURRENT_DATE - INTERVAL '30 days';
      SQL
    else
      raise "This migration is only supported for Redshift."
    end
  end

  def down
    if connection.adapter_name.downcase.include?("redshift")
      # Drop the backup tables
      execute 'DROP TABLE IF EXISTS logs.events_backup;'
      execute 'DROP TABLE IF EXISTS logs.production_backup;'
    else
      raise "This migration is only supported for Redshift."
    end
  end
end
