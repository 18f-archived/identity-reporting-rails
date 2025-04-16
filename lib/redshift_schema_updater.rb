require 'yaml'

class RedshiftSchemaUpdater
  def initialize(schema_name)
    @schema_name = schema_name
  end

  def using_redshift_adapter?
    DataWarehouseApplicationRecord.
      connection.adapter_name.downcase.include?('redshift')
  end

  def update_schema_from_yaml(file_path)
    yaml_data = load_yaml(file_path)
    return unless yaml_data

    yaml_data.each do |table_data|
      table_name = "#{@schema_name}.#{table_data['table']}"
      columns = table_data['include_columns']
      primary_key_column = table_data['primary_key']
      foreign_key_columns = table_data['foreign_keys'] || []

      if table_exists?(table_name)
        update_existing_table(table_name, columns, primary_key_column, foreign_key_columns)
      else
        create_table(table_name, columns, primary_key_column, foreign_key_columns)
      end
    end
  rescue StandardError => e
    log_error("Error updating schema from YAML: #{e.message}")
    DataWarehouseApplicationRecord.connection.rollback_db_transaction
    raise e
  end

  def table_exists?(table_name)
    DataWarehouseApplicationRecord.connection.table_exists?(table_name)
  rescue StandardError => e
    log_error("Error checking table existence: #{e.message}")
    DataWarehouseApplicationRecord.connection.rollback_db_transaction
    false
  end

  def column_exists?(table_name, column_name)
    DataWarehouseApplicationRecord.connection.columns(table_name).map(&:name).include?(column_name)
  end

  def primary_key_exists?(table_name, column_name)
    # Check if the table has a primary key
    return false unless table_exists?(table_name) && column_exists?(table_name, column_name)
    query = <<~SQL
      SELECT kcu.column_name
      FROM information_schema.table_constraints tco
      JOIN information_schema.key_column_usage kcu
      ON kcu.constraint_name = tco.constraint_name
      WHERE tco.table_name = ? AND tco.constraint_type = 'PRIMARY KEY'
    SQL
    # Check if the primary key exists for a given table
    if using_redshift_adapter?
      primary_key_info =
        DataWarehouseApplicationRecord.connection.exec_query(
          DataWarehouseApplicationRecord.sanitize_sql([query, table_name]),
        ).to_a
      primary_key_info.any? { |pk| pk['column_name'] == column_name }
    else
      DataWarehouseApplicationRecord.connection.primary_key(table_name) == column_name
    end
  rescue StandardError => e
    log_error("Error checking primary key: #{e.message}")
    raise e
  end

  def foreign_key_exists?(table_name, foreign_column)
    # Check if the table has a foreign key
    return false unless table_exists?(table_name) && column_exists?(table_name, foreign_column)

    # Check if the foreign key exists for a given table
    if using_redshift_adapter?
      query = <<~SQL
        SELECT kcu.column_name
        FROM information_schema.table_constraints tco
        JOIN information_schema.key_column_usage kcu
        ON kcu.constraint_name = tco.constraint_name
        WHERE tco.table_name = ? AND tco.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = ?
      SQL
      foreign_key_info =
        DataWarehouseApplicationRecord.connection.exec_query(
          DataWarehouseApplicationRecord.sanitize_sql([query, table_name, foreign_column]),
        ).to_a
      foreign_key_info.any?
    else
      DataWarehouseApplicationRecord.connection.foreign_keys(table_name).any? do |fk|
        fk.name == foreign_column
      end
    end
  rescue StandardError => e
    log_error("Error checking foreign key: #{e.message}")
    raise e
  end

  def get_config_column_options(column_info)
    config_column_data_type = column_info.fetch('datatype')
    default_varchar_limit = nil
    if using_redshift_adapter? && ['string', 'text'].include?(config_column_data_type)
      default_varchar_limit = 256
    end
    {
      limit: column_info.fetch('limit', default_varchar_limit),
      if_not_exists: true,
    }
  end

  def update_existing_table(table_name, columns, primary_key, foreign_keys)
    columns_objs = DataWarehouseApplicationRecord.connection.columns(table_name)
    existing_columns = columns_objs.map(&:name)

    # rubocop:disable Metrics/BlockLength
    columns.each do |column_info|
      config_column_name, config_column_data_type = column_info.values_at('name', 'datatype')
      datatype_metadata = columns_objs.find { |x| x.name == config_column_name }
      config_column_options = get_config_column_options(column_info)
      column_exists = existing_columns.include?(config_column_name)

      if column_exists
        current_dw_data_types = [
          datatype_metadata.type.to_s,
          datatype_metadata.sql_type,
        ]
        data_type_requires_update = current_dw_data_types.exclude?(
          redshift_data_type(config_column_data_type),
        )
        is_string_data_type = (current_dw_data_types & ['string', 'text']).any?
        limit_changed = datatype_metadata.limit != config_column_options[:limit]
        varchar_requires_update = is_string_data_type && limit_changed
      end

      if !column_exists
        add_column(
          table_name,
          config_column_name,
          config_column_data_type,
          config_column_options,
        )
      elsif varchar_requires_update
        # Redshift supports altering the length of a VARCHAR column in place.
        update_varchar_length(table_name, config_column_name, config_column_options[:limit])
      elsif data_type_requires_update
        # Redshift does not support altering data type in place. Therefore, dropping
        # the column and adding it back with the new data type is required.
        update_column_data_type(
          table_name, config_column_name, config_column_data_type,
          config_column_options
        )
      end
    end
    # rubocop:enable Metrics/BlockLength

    existing_columns.each do |existing_column_name|
      column_names = columns.map { |item| item['name'] }
      unless column_names.include?(existing_column_name)
        remove_column(
          table_name,
          existing_column_name,
        )
      end
    end
    # check if primary key exists on the table other wise add it
    if primary_key && !primary_key_exists?(table_name, primary_key)
      add_primary_key(table_name, primary_key)
    elsif primary_key && primary_key_exists?(table_name, primary_key)
      log_info("Primary key column already exists: #{primary_key}")
    else
      log_error("No primary key found in the YAML file for table: #{table_name}")
    end

    # add foreign keys if they do not exist
    if foreign_keys.any?
      foreign_keys.each do |foreign_key|
        foreign_key_column = foreign_key['column']
        if foreign_key_exists?(table_name, foreign_key_column)
          log_warning("Foreign key column already exists: #{foreign_key_column}")
        else
          add_foreign_key(table_name, foreign_key)
        end
      end
    end
  rescue StandardError => e
    log_error("Error updating existing table: #{e.message}")
    raise e
  end

  # Add primary key to the table if it does not exist

  def add_primary_key(table_name, primary_key)
    table_short_value = table_name.split('.').last
    primary_key_name = "  #{table_short_value}_#{primary_key}_pkey "

    if primary_key_exists?(table_name, primary_key)
      log_info("Primary key column already exists: #{primary_key}")
      return
    end

    # Ensure the primary key column is NOT NULL
    alter_column_to_not_null_sql = <<~SQL
      ALTER TABLE #{table_name}
      ALTER COLUMN #{primary_key} SET NOT NULL;
    SQL
    DataWarehouseApplicationRecord.connection.execute(
      DataWarehouseApplicationRecord.sanitize_sql(alter_column_to_not_null_sql),
    )
    log_info("Column #{primary_key} set to NOT NULL for table: #{table_name}")

    sql = if using_redshift_adapter?
            "ALTER TABLE #{table_name} ADD PRIMARY KEY (#{primary_key});"
          else
            <<~SQL
              ALTER TABLE #{table_name}
              ADD CONSTRAINT #{primary_key_name}
              PRIMARY KEY (#{primary_key});
            SQL
          end
    DataWarehouseApplicationRecord.connection.execute(
      DataWarehouseApplicationRecord.sanitize_sql(sql),
    )
    log_info("Primary key column added: #{primary_key}")
  rescue StandardError => e
    log_error("Error adding primary key: #{e.message}")
    raise e
  end
  # Add foreign keys to the table if they do not exist

  def add_foreign_key(table_name, foreign_key)
    foreign_key_column = foreign_key['column']
    foreign_key_reference_table = "#{@schema_name}.#{foreign_key['references']['table']}"
    foreign_key_reference_column = foreign_key['references']['column']
    table_short_name = table_name.split('.').last
    foreign_key_name = "#{table_short_name}_#{foreign_key_column}_fkey"
    # check if reference table exists
    unless table_exists?(foreign_key_reference_table)
      log_error("Reference table does not exist: #{foreign_key_reference_table}")
      return
    end
    sql = <<~SQL
      ALTER TABLE #{table_name}
      ADD CONSTRAINT #{foreign_key_name}
      FOREIGN KEY (#{foreign_key_column})
      REFERENCES #{foreign_key_reference_table} (#{foreign_key_reference_column});
    SQL
    DataWarehouseApplicationRecord.connection.execute(
      DataWarehouseApplicationRecord.sanitize_sql(sql),
    )

    log_info("Foreign key column added: #{foreign_key_name} on column: #{foreign_key_column}")
  rescue StandardError => e
    log_error("Error adding foreign keys: #{e.message}")
    raise e
  end

  def create_table(table_name, columns, primary_key, foreign_keys)
    DataWarehouseApplicationRecord.connection.create_table(table_name, id: false) do |t|
      columns.each do |column_info|
        column_name, column_data_type = column_info.values_at('name', 'datatype')
        config_column_options = get_config_column_options(column_info)

        t.column column_name, redshift_data_type(column_data_type), **config_column_options
      end
    end
    log_info("Table created: #{table_name}")
    if primary_key
      add_primary_key(table_name, primary_key) unless primary_key_exists?(table_name, primary_key)
    else
      log_error("No primary key found in the YAML file for table: #{table_name}")
    end
    if foreign_keys.any?
      foreign_keys.each do |foreign_key|
        foreign_key_column = foreign_key['column']
        add_foreign_key(table_name, foreign_key) unless foreign_key_exists?(
          table_name,
          foreign_key_column,
        )
      end
      Rails.logger.debug { "Foreign keys added: #{foreign_keys}" }
    end
  rescue StandardError => e
    log_error("Error creating table: #{e.message}")
    DataWarehouseApplicationRecord.connection.rollback_db_transaction
    raise e
  end

  def add_column(table_name, column_name, data_type, column_options = {})
    DataWarehouseApplicationRecord.connection.add_column(
      table_name,
      column_name,
      redshift_data_type(data_type),
      **column_options,
    )
  end

  def remove_column(table_name, column_name)
    DataWarehouseApplicationRecord.connection.remove_column(
      table_name, column_name, if_exists: true
    )
  end

  def update_varchar_length(table_name, column_name, new_limit)
    if using_redshift_adapter?
      DataWarehouseApplicationRecord.connection.execute(
        DataWarehouseApplicationRecord.sanitize_sql(
          "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} TYPE VARCHAR(#{new_limit})",
        ),
      )
    else
      DataWarehouseApplicationRecord.connection.change_column(
        table_name, column_name, 'string', limit: new_limit
      )
    end
  end

  def update_column_data_type(table_name, column_name, new_data_type, keyword_options)
    old_column_name = "#{column_name}_copy"
    rename_column(table_name, column_name, old_column_name)
    add_column(table_name, column_name, new_data_type, keyword_options)
    backfill_column(table_name, old_column_name, column_name)
    remove_column(table_name, old_column_name)
  end

  def rename_column(table_name, old_column_name, new_column_name)
    DataWarehouseApplicationRecord.connection.rename_column(
      table_name, old_column_name, new_column_name
    )
  end

  def backfill_column(table_name, from_column, to_column)
    DataWarehouseApplicationRecord.connection.execute(
      DataWarehouseApplicationRecord.sanitize_sql(
        "UPDATE #{table_name} SET #{to_column} = #{from_column};",
      ),
    )
  end

  def redshift_data_type(datatype)
    case datatype
    when 'json', 'jsonb'
      'super'
    when 'text'
      'string'
    else
      datatype
    end
  end

  private

  def log_error(message)
    logger.error(
      {
        name: self.class.name,
        error: message,
      }.to_json,
    )
  end

  def log_info(message)
    logger.info(
      {
        name: self.class.name,
        info: message,
      }.to_json,
    )
  end

  def log_warning(message)
    logger.warn(
      {
        name: self.class.name,
        warning: message,
      }.to_json,
    )
  end

  def logger
    @logger ||= IdentityJobLogSubscriber.new.logger
  end

  def load_yaml(file_path)
    YAML.load_file(file_path)
  rescue StandardError => e
    log_error("Error loading include columns YML file: #{e.message}")
    nil
  end
end
