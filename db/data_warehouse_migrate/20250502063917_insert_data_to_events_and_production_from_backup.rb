class InsertDataToEventsAndProductionFromBackup < ActiveRecord::Migration[7.2]
  def up
    if connection.adapter_name.downcase.include?("redshift")
      # Insert data from backup tables to main tables
      execute <<-SQL
        INSERT INTO logs.events (
          message,
          cloudwatch_timestamp,
          id,
          name,
          time,
          visitor_id,
          visit_id,
          log_filename,
          new_event,
          path,
          user_id,
          locale,
          user_ip,
          hostname,
          pid,
          service_provider,
          trace_id,
          git_sha,
          git_branch,
          user_agent,
          browser_name,
          browser_version,
          browser_platform_name,
          browser_platform_version,
          browser_device_name,
          browser_mobile,
          browser_bot,
          success
        )
        SELECT
          message,
          cloudwatch_timestamp,
          id,
          name,
          "time",
          visitor_id,
          visit_id,
          log_filename,
          new_event,
          path,
          user_id,
          locale,
          user_ip,
          hostname,
          pid,
          service_provider,
          trace_id,
          git_sha,
          git_branch,
          user_agent,
          browser_name,
          browser_version,
          browser_platform_name,
          browser_platform_version,
          browser_device_name,
          browser_mobile,
          browser_bot,
          success
        FROM logs.events_backup;
      SQL

      execute <<-SQL
        INSERT INTO logs.production (
          message,
          cloudwatch_timestamp,
          uuid,
          method,
          path,
          format,
          controller,
          action,
          status,
          duration,
          git_sha,
          git_branch,
          timestamp,
          pid,
          user_agent,
          ip,
          host,
          trace_id
        )
        SELECT
          message,
          cloudwatch_timestamp,
          uuid,
          method,
          path,
          format,
          controller,
          action,
          status,
          duration,
          git_sha,
          git_branch,
          "timestamp",
          pid,
          user_agent,
          ip,
          host,
          trace_id
        FROM logs.production_backup;
      SQL
    else
      Rails.logger.warn("Skipping InsertDataToEventsAndProductionFromBackup for non Redshift.")
    end
  end

  def down
    if connection.adapter_name.downcase.include?("redshift")
      # No rollback action needed as this is a one-time migration.
      execute <<-SQL
        DELETE FROM logs.events WHERE id IN (
          SELECT id FROM logs.events_backup
        );
      SQL
      execute <<-SQL
        DELETE FROM logs.production WHERE uuid IN (
          SELECT uuid FROM logs.production_backup
        );
      SQL
    else
      Rails.logger.warn("Skipping rollback for InsertDataToEventsAndProductionFromBackup for non Redshift.")
    end
  end

end
