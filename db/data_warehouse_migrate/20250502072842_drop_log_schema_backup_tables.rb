class DropLogSchemaBackupTables < ActiveRecord::Migration[7.2]
  def up
    if connection.adapter_name.downcase.include?("redshift")
      # Drop the backup tables
      execute 'DROP TABLE IF EXISTS logs.events_backup;'
      execute 'DROP TABLE IF EXISTS logs.production_backup;'
    else
      Rails.logger.warn("Skipping DropLogSchemaBackupTables for non Redshift.")
    end
  end

  def down
    if connection.adapter_name.downcase.include?("redshift")
      # Recreate the backup tables
      execute 'CREATE TABLE IF NOT EXISTS logs.events_backup (LIKE logs.events);'
      execute 'CREATE TABLE IF NOT EXISTS logs.production_backup (LIKE logs.production);'
    else
      Rails.logger.warn("Skipping rollback DropLogSchemaBackupTables for non Redshift.")
    end
  end
end
