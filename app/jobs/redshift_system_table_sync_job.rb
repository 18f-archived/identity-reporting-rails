class RedshiftSystemTableSyncJob < ApplicationJob
  queue_as :default

  def perform
    table_definitions.each do |table|
      setup_instance_variables(table)
      create_target_table
      last_sync_time = fetch_last_sync_time
      upsert_data(last_sync_time)
      update_sync_time
    end
  end

  private

  def table_definitions
    YAML.load_file(config_file_path)['tables']
  end

  def config_file_path
    Rails.root.join('config/redshift_system_tables.yml')
  end

  def setup_instance_variables(table)
    @target_schema = table['target_schema']
    @source_table = table['name']
    @target_table = table['target_table']
    @timestamp_column = table['timestamp_column']
    @primary_key = table['primary_key']
    @target_table_with_schema = [@target_schema, @target_table].join('.')
  end

  def target_table_exists?
    SystemMetadataApplicationRecord.connection.table_exists?(@target_table_with_schema)
  end

  def create_target_table
    return if target_table_exists?

    create_schema_if_not_exists

    columns = fetch_source_columns

    SystemMetadataApplicationRecord.connection.create_table(
      @target_table_with_schema,
      id: false,
    ) do |t|
      columns.each do |column_info|
        column_name, column_data_type = column_info.values_at('column', 'type')
        config_column_options = get_config_column_options(column_info)

        t.column column_name, column_data_type, **config_column_options
      end
    end

    log_info(
      "Created target table #{@target_table_with_schema}", true,
      target_table: @target_table_with_schema
    )
  end

  def create_schema_if_not_exists
    schema_query = "CREATE SCHEMA IF NOT EXISTS #{@target_schema}"
    SystemMetadataApplicationRecord.connection.execute(schema_query)
    log_info("Schema #{@target_schema} created", true)
  rescue ActiveRecord::StatementInvalid => e
    if /unacceptable schema name/i.match?(e.message)
      log_info("Schema #{@target_schema} already created", true)
    else
      log_info(e.message, false)
      raise e
    end
  end

  def fetch_source_columns
    build_params = {
      source_table: @source_table,
      source_schema: @target_schema,
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
    log_info("Columns fetched for #{@source_table}", true) if columns.present?

    columns
  end

  def get_config_column_options(_column_info)
    {}
  end

  def upsert_data(last_sync_time)
    if DataWarehouseApplicationRecord.connection.adapter_name.downcase.include?('redshift')
      perform_merge_upsert
    else
      perform_insert_on_conflict(last_sync_time)
    end
  end

  def perform_merge_upsert
    columns = fetch_source_columns.map { |col| col['column'] }
    update_assignments = columns.map { |col| "target.#{col} = source.#{col}" }.join(', ')
    insert_columns = columns.join(', ')
    insert_values = columns.map { |col| "source.#{col}" }.join(', ')

    merge_query = <<-SQL.squish
      MERGE INTO #{@target_table_with_schema} AS target
      USING #{@source_table} AS source
      ON target.#{@primary_key} = source.#{@primary_key}
      WHEN MATCHED AND source.#{@timestamp_column} > target.#{@timestamp_column} THEN
        UPDATE SET #{update_assignments}
      WHEN NOT MATCHED THEN
        INSERT (#{@primary_key}, #{insert_columns})
        VALUES (source.#{@primary_key}, #{insert_values});
    SQL

    SystemMetadataApplicationRecord.connection.execute(merge_query)
    log_info("MERGE executed for #{@target_table_with_schema}", true)
  end

  def perform_insert_on_conflict(last_sync_time)
    columns = fetch_source_columns.map { |col| col['column'] }
    insert_columns = columns.join(', ')
    insert_values = columns.map { |col| "source.#{col}" }.join(', ')
    update_assignments = columns.map { |col| "#{col} = EXCLUDED.#{col}" }.join(', ')

    insert_query = <<-SQL.squish
      INSERT INTO #{@target_table_with_schema} (#{insert_columns})
      SELECT #{insert_values}
      FROM #{@source_table} AS source
      WHERE source.#{@timestamp_column} > '#{last_sync_time}'
      SET #{update_assignments};
    SQL

    SystemMetadataApplicationRecord.connection.execute(insert_query)
    log_info("INSERT ON CONFLICT executed for #{@target_table_with_schema}", true)
  end

  def fetch_last_sync_time
    sync_metadata = SystemTableSyncMetadata.find_by(table_name: @target_table_with_schema)
    sync_metadata&.last_sync_time || (Time.zone.now - 6.days)
  end

  def update_sync_time
    sync_metadata = SystemTableSyncMetadata.find_or_initialize_by(table_name: @target_table_with_schema)
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
