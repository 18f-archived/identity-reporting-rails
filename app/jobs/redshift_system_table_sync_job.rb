class RedshiftSystemTableSyncJob < ApplicationJob
  queue_as :default

  def perform
    table_definitions = YAML.load_file(Rails.root.join('config/redshift_system_tables.yml'))['tables']

    table_definitions.each do |table|
      unless target_table_exists?(table['target_table'])
        create_target_table(table['target_table'], table['name'])
      end

      last_sync_time = fetch_last_sync_time(table['name'])
      new_data = fetch_recent_data(table['name'], table['timestamp_column'], last_sync_time)

      if new_data.empty?
        log_info(
          'Missing data in source table',
          false,
          source_table_name: table['name'],
          last_sync_time: last_sync_time,
        )
        next
      end

      upsert_data(table['target_table'], table['primary_key'], new_data)
      update_sync_time(table['name'])
      log_info("Upserted data into #{table['target_table']}", true, record_count: new_data.size)
    end
  end

  private

  def log_info(message, success, additional_info = {})
    Rails.logger.info(
      {
        job: self.class.name,
        success: success,
        message: message,
      }.merge(additional_info).to_json,
    )
  end

  def target_table_exists?(table_name)
    DataWarehouseApplicationRecord.connection.table_exists?(table_name)
  end

  def create_target_table(target_table, source_table)
    columns = fetch_source_columns(source_table)

    DataWarehouseApplicationRecord.connection.create_table(target_table) do |t|
      columns.each do |column_info|
        column_name, column_data_type = column_info.values_at('name', 'datatype')
        config_column_options = get_config_column_options(column_info)
        next if column_name == 'id'

        t.column column_name, column_data_type, **config_column_options
      end
    end
    log_info("Created target table #{target_table}", true, target_table: target_table)
  end

  def fetch_source_columns(source_table)
    query = <<-SQL
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = '#{source_table}';
    SQL

    DataWarehouseApplicationRecord.connection.exec_query(query).to_a
  end

  def get_config_column_options(_column_info)
    {}
  end

  def fetch_last_sync_time(table_name)
    sync_metadata = SystemTableSyncMetadata.find_by(table_name: table_name)
    sync_metadata ? sync_metadata.last_sync_time : (Time.zone.now - 5.days)
  end

  def fetch_recent_data(table_name, timestamp_column, last_sync_time)
    query = <<-SQL
      SELECT *
      FROM #{table_name}
      WHERE #{timestamp_column} > '#{last_sync_time}';
    SQL

    data = []
    DataWarehouseApplicationRecord.connection.exec_query(query).each do |row|
      data << row
    end
    data
  end

  def upsert_data(target_table, primary_key, data)
    data.each do |row|
      values = row.values.map { |value| ActiveRecord::Base.connection.quote(value) }.join(', ')
      insert_sql = <<-SQL
        INSERT INTO #{target_table} (#{row.keys.join(", ")})
        VALUES (#{values})
        ON CONFLICT (#{primary_key}) DO UPDATE SET
          #{row.keys.map { |key| "#{key} = EXCLUDED.#{key}" }.join(", ")};
      SQL
      DataWarehouseApplicationRecord.connection.execute(insert_sql)
    end
  end

  def update_sync_time(table_name)
    timestamp = Time.zone.now
    sync_metadata = SystemTableSyncMetadata.find_or_initialize_by(table_name: table_name)
    sync_metadata.last_sync_time = timestamp
    sync_metadata.save!
  end
end
