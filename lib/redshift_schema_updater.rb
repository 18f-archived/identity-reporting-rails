require 'yaml'

class RedshiftSchemaUpdater
  def initialize(schema_name)
    @schema_name = schema_name
  end

  def update_schema_from_yaml(file_path)
    yaml_data = load_yaml(file_path)
    return unless yaml_data

    yaml_data.each do |table_data|
      table_name = "#{@schema_name}.#{table_data['table']}"
      columns = table_data['include_columns']

      if table_exists?(table_name)
        update_existing_table(table_name, columns)
      else
        create_table(table_name, columns)
      end
    end
  end

  def table_exists?(table_name)
    DataWarehouseApplicationRecord.connection.table_exists?(table_name)
  end

  def update_existing_table(table_name, columns)
    columns_objs = DataWarehouseApplicationRecord.connection.columns(table_name)
    existing_columns = columns_objs.map(&:name)
    data_types = columns_objs.each_with_object({}) do |column, hash|
      hash[column.name] = column.type.to_s
    end
    sql_data_types = columns_objs.each_with_object({}) do |column, hash|
      hash[column.name] = column.sql_type
    end

    columns.each do |column_info|
      config_column_name, config_column_data_type = column_info.values_at('name', 'datatype')
      column_exists = existing_columns.include?(config_column_name)
      data_type_matches = [data_types.fetch(config_column_name, nil),
                           sql_data_types.fetch(
                             config_column_name,
                             nil,
                           )].include?(redshift_data_type(config_column_data_type))

      unless column_exists && data_type_matches
        if column_exists && !data_type_matches
          # Redshift does not support altering data type in place. Therefore, dropping
          # the column and adding it back with the new data type is required.
          update_column_data_type(table_name, config_column_name, config_column_data_type)
        end
        add_column(
          table_name,
          config_column_name,
          config_column_data_type,
        )
      end
    end

    existing_columns.each do |existing_column_name|
      column_names = columns.map { |item| item['name'] }
      unless column_names.include?(existing_column_name)
        remove_column(
          table_name,
          existing_column_name,
        )
      end
    end
  end

  def create_table(table_name, columns)
    DataWarehouseApplicationRecord.connection.create_table(table_name) do |t|
      columns.each do |column_info|
        column_name, column_data_type = column_info.values_at('name', 'datatype')
        next if column_name == 'id'

        t.column column_name, redshift_data_type(column_data_type)
      end
    end
  end

  def add_column(table_name, column_name, data_type)
    DataWarehouseApplicationRecord.connection.add_column(
      table_name,
      column_name,
      redshift_data_type(data_type),
      if_not_exists: true,
    )
  end

  def remove_column(table_name, column_name)
    DataWarehouseApplicationRecord.connection.remove_column(
      table_name, column_name, if_exists: true
    )
  end

  def update_column_data_type(table_name, column_name, new_data_type)
    old_column_name = "#{column_name}_copy"
    rename_column(table_name, column_name, old_column_name)
    add_column(table_name, column_name, new_data_type)
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
    else
      datatype
    end
    # Some fields in the source database are stored as TEXT data type, these fields have
    # unlimited length, however, the TEXT data type in Redshift has a default length of
    # 256 characters. This could cause errors when trying to insert data into Redshift if
    # the source data is longer than 256 characters.
  end

  private

  def load_yaml(file_path)
    YAML.load_file(file_path)
  rescue StandardError => e
    Rails.logger.error "Error loading include columns YML file: #{e.message}"
    nil
  end
end
