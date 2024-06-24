class LogsColumnExtractorJob < ApplicationJob
  queue_as :default
  attr_reader :query

  def perform(target_table_name:)
    ##
    # This job is used to extract columns from the message column in the logs tables
    # and store them in their respective columns in the target table.
    # In general, the rails job executes a block of SQL code to extract the columns,
    # the block of SQL code is broken down into the following steps:
    # 1. Lock the unextracted source table to prevent other processes from modifying it
    # 2. Create a temporary table to store the extracted columns using data from the source table
    # 3. Remove duplicate rows from the temporary table if any
    # 4. Merge the temporary table with the target table
    # 5. Truncate the unextracted source table

    @schema_name = 'logs'
    @source_table_name = "unextracted_#{target_table_name}"

    Rails.logger.info(<<~STR.squish)
      LogsColumnExtractorJob: Processing records from source
      #{@source_table_name} to target #{@schema_name}.#{target_table_name}
    STR

    merge_key = get_unique_id
    @query = DataWarehouseApplicationRecord.sanitize_sql(
      <<~SQL,
        BEGIN;
        LOCK #{@schema_name}.#{@source_table_name};
        CREATE TEMP TABLE #{@source_table_name}_temp AS
        #{select_message_fields}
        FROM #{@schema_name}.#{@source_table_name};
        WITH duplicate_rows as (
            SELECT #{merge_key}
            , ROW_NUMBER() OVER (PARTITION BY #{merge_key} ORDER BY cloudwatch_timestamp desc) as row_num
            FROM #{@source_table_name}_temp
        )
        DELETE FROM #{@source_table_name}_temp
        USING duplicate_rows
        WHERE duplicate_rows.#{merge_key} = #{@source_table_name}_temp.#{merge_key} and duplicate_rows.row_num > 1;
        MERGE INTO #{@schema_name}.#{target_table_name}
        USING #{@source_table_name}_temp
        ON #{@schema_name}.#{target_table_name}.#{merge_key} = #{@source_table_name}_temp.#{merge_key}
        REMOVE DUPLICATES;
        TRUNCATE #{@schema_name}.#{@source_table_name};
        COMMIT;
      SQL
    )

    Rails.logger.info "LogsColumnExtractorJob: Executing query: #{@query}"
    DataWarehouseApplicationRecord.connection.execute(@query)
    Rails.logger.info 'LogsColumnExtractorJob: Query executed successfully'
  end

  def select_message_fields
    # THE ORDER OF THE FIELDS IN THE SELECT QUERY SHOULD MATCH THE ORDER OF THE FIELDS
    # IN THE TARGET TABLE; ADDITIONALLY FIELDS LISTED HERE SHOULD CONINCIDE WITH MIGRATIONS
    # MADE TO THE ASSOCIATED TABLES. FOR EXAMPLE, IF A COLUMN IS ADDED OR REMOVED FROM THE
    # EVENTS TABLE, THE SELECT QUERY SHOULD BE UPDATED TO REFLECT THE CHANGE.
    if @source_table_name == 'unextracted_events'
      select_query = <<~SQL
            SELECT
                message
                , cloudwatch_timestamp 
                , #{extract_json_key(column: 'message', key: 'id')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'name')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'time')}::TIMESTAMP 
                , #{extract_json_key(column: 'message', key: 'visitor_id')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'visit_id')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'log_filename')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.new_event')}::BOOLEAN 
                , #{extract_json_key(column: 'message', key: 'properties.path')}::VARCHAR(12000) 
                , #{extract_json_key(column: 'message', key: 'properties.user_id')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.locale')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.user_ip')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.hostname')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.pid')}::INTEGER 
                , #{extract_json_key(column: 'message', key: 'properties.service_provider')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.trace_id')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.git_sha')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.git_branch')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.user_agent')}::VARCHAR(12000) 
                , #{extract_json_key(column: 'message', key: 'properties.browser_name')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.browser_version')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.browser_platform_name')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'properties.browser_platform_version')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.browser_device_name')}::VARCHAR 
                , #{extract_json_key(column: 'message', key: 'properties.browser_mobile')}::BOOLEAN 
                , #{extract_json_key(column: 'message', key: 'properties.browser_bot')}::BOOLEAN 
                , #{extract_json_key(column: 'message', key: 'properties.event_properties.success')}::BOOLEAN 
      SQL
    elsif @source_table_name == 'unextracted_production'
      select_query = <<~SQL
            SELECT
                message
                , cloudwatch_timestamp
                , #{extract_json_key(column: 'message', key: 'uuid')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'method')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'path')}::VARCHAR(12000)
                , #{extract_json_key(column: 'message', key: 'format')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'controller')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'action')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'status')}::INTEGER
                , #{extract_json_key(column: 'message', key: 'duration')}::FLOAT
                , #{extract_json_key(column: 'message', key: 'git_sha')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'git_branch')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'timestamp')}::TIMESTAMP
                , #{extract_json_key(column: 'message', key: 'pid')}::INTEGER
                , #{extract_json_key(column: 'message', key: 'user_agent')}::VARCHAR(12000) 
                , #{extract_json_key(column: 'message', key: 'ip')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'host')}::VARCHAR
                , #{extract_json_key(column: 'message', key: 'trace_id')}::VARCHAR
      SQL
    else
      raise "Invalid source table name: #{source_table_name}"
    end
    select_query.strip
  end

  def get_unique_id
    if @source_table_name in 'unextracted_events'
      'id'
    elsif @source_table_name in 'unextracted_production'
      'uuid'
    else
      raise "Invalid source table name: #{source_table_name}"
    end
  end

  def extract_json_key(column:, key:)
    if Rails.env.production?
      # Redshift environment using SUPER Column type
      "#{column}.#{key}"
    else
      # Local/Test environment using JSONB Column type
        key_parts = key.split('.')
        key_parts.map! { |part| part.include?("'") ? part : "'#{part}'" }
        "(#{column}->#{key_parts.join('->')})"
    end
  end

  end
