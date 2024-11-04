class RedshiftSystemTableSyncJob < ApplicationJob
  queue_as :default

  def perform
    table_definitions.each do |table|
      target_schema = table['target_schema']
      source_table = table['name']
      target_table = table['target_table']
      target_table_with_schema = [target_schema, target_table].join('.')
      timestamp_column = table['timestamp_column']
      primary_key = table['primary_key']

      create_target_table(source_table, target_table_with_schema, target_schema)
      last_sync_time = fetch_last_sync_time(target_table_with_schema)
      upsert_data(source_table, target_table_with_schema, target_schema, primary_key, timestamp_column)
      update_sync_time(target_table_with_schema)
    end
  end

  private

  def table_definitions
    YAML.load_file(config_file_path)['tables']
  end

  def config_file_path
    Rails.root.join('config/redshift_system_tables.yml')
  end

  def target_table_exists?(table_name)
    SystemMetadataApplicationRecord.connection.table_exists?(table_name)
  end

  def create_target_table(source_table, target_table_with_schema, target_schema)
    return if target_table_exists?(target_table_with_schema)

    create_schema_if_not_exists(target_schema)

    columns = fetch_source_columns(source_table, target_schema)

    SystemMetadataApplicationRecord.connection.create_table(
      target_table_with_schema,
      id: false,
    ) do |t|
      columns.each do |column_info|
        column_name, column_data_type = column_info.values_at('column', 'type')
        config_column_options = get_config_column_options(column_info)

        t.column column_name, column_data_type, **config_column_options
      end
    end

    log_info(
      "Created target table #{target_table_with_schema}", true,
      target_table: target_table_with_schema
    )
  end

  def create_schema_if_not_exists(target_schema)
    begin
      schema_query = "CREATE SCHEMA IF NOT EXISTS #{target_schema}"
      SystemMetadataApplicationRecord.connection.execute(schema_query)
      log_info("Schema #{target_schema} created", true)
    rescue ActiveRecord::StatementInvalid => e
      if /unacceptable schema name/i.match?(e.message)
        log_info("Schema #{target_schema} already created", true)
      else
        log_info(e.message.join(','), false)
        raise e
      end
    end
  end

  def fetch_source_columns(source_table, source_schema)
    build_params = {
      source_table: source_table,
      source_schema: source_schema,
    }

    if DataWarehouseApplicationRecord.connection.adapter_name.downcase.include?('redshift')
      query = format(<<~SQL, build_params)
        SELECT *
        FROM pg_table_def
        WHERE schemaname= '%{source_schema}' AND tablename = '%{source_table}';
      SQL
    else
      query = format(<<~SQL, build_params)
        SELECT column_name AS column, data_type AS type
        FROM information_schema.columns
        WHERE table_schema = '%{source_schema}' AND table_name = '%{source_table}';
      SQL
    end

    columns = DataWarehouseApplicationRecord.connection.exec_query(query).to_a
    log_info("Columns fetched for #{source_table}", true) if columns.present?

    columns
  end

  def get_config_column_options(_column_info)
    {}
  end

  def upsert_data(source_table, target_table_with_schema, target_schema, primary_key, timestamp_column)
    columns = fetch_source_columns(source_table, target_schema).map { |col| col['column'] }
    update_assignments = columns.map { |col| "target.#{col} = source.#{col}" }.join(', ')
    insert_columns = columns.join(', ')
    insert_values = columns.map { |col| "source.#{col}" }.join(', ')

    merge_query = <<-SQL.squish
      MERGE INTO #{target_table_with_schema} AS target
      USING #{source_table} AS source
      ON target.#{primary_key} = source.#{primary_key}
      WHEN MATCHED AND source.#{timestamp_column} > target.#{timestamp_column} THEN
        UPDATE SET #{update_assignments}
      WHEN NOT MATCHED THEN
        INSERT (#{primary_key}, #{insert_columns})
        VALUES (source.#{primary_key}, #{insert_values});
    SQL

    log_info("Executing MERGE for #{target_table_with_schema}", true)
    begin
      SystemMetadataApplicationRecord.connection.execute(merge_query)
      log_info("Merge successful for #{target_table_with_schema}", true)
    rescue ActiveRecord::StatementInvalid => e
      log_info("Merge failed for #{target_table_with_schema}: #{e.message}", false)
      raise e
    end
  end

  def fetch_last_sync_time(table_name)
    sync_metadata = SystemTableSyncMetadata.find_by(table_name: table_name)
    sync_metadata&.last_sync_time || (Time.zone.now - 6.days)
  end

  def update_sync_time(table_name)
    sync_metadata = SystemTableSyncMetadata.find_or_initialize_by(table_name: table_name)
    sync_metadata.last_sync_time = Time.zone.now
    sync_metadata.save!
  end

  def log_info(message, success, additional_info = {})
    Rails.logger.info(
      {
        job: self.class.name,
        success: success,
        message: message,
      }.merge(additional_info).to_json,
    )
  end
end
