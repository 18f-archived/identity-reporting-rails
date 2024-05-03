require 'yaml'

module RedshiftSchemaUpdater
  class << self
    def update_schema_from_yaml(file_path)
      establish_data_warehouse_connection

      yaml_data = load_yaml(file_path)
      return unless yaml_data

      yaml_data.each do |table_data|
        table_name = table_data['table']
        columns = table_data['include_columns']

        if table_exists?(table_name)
          update_existing_table(table_name, columns)
        else
          create_table(table_name, columns)
        end
      end
    end

    private

    def establish_data_warehouse_connection
      ActiveRecord::Base.establish_connection(:data_warehouse)
    end

    def load_yaml(file_path)
      YAML.load_file(file_path)
    rescue StandardError => e
      Rails.logger.error "Error loading include columns YML file: #{e.message}"
      nil
    end

    def table_exists?(table_name)
      ActiveRecord::Base.connection.table_exists?(table_name)
    end

    def update_existing_table(table_name, columns)
      existing_columns = ActiveRecord::Base.connection.columns(table_name).map(&:name)

      columns.each do |column_name, column_info|
        unless existing_columns.include?(column_name)
          add_column(
            table_name, column_name,
            column_info['datatype']
          )
        end
      end

      existing_columns.each do |existing_column_name|
        remove_column(table_name, existing_column_name) unless columns.key?(existing_column_name)
      end
    end

    def create_table(table_name, columns)
      ActiveRecord::Base.connection.create_table(table_name.to_sym) do |t|
        columns.each do |column_name, column_info|
          next if column_name == 'id'

          t.send(column_info['datatype'].to_sym, column_name.to_sym)
        end
      end
    end

    def add_column(table_name, column_name, data_type)
      ActiveRecord::Base.connection.add_column(
        table_name.to_sym, column_name.to_sym,
        data_type.to_sym
      )
    end

    def remove_column(table_name, column_name)
      ActiveRecord::Base.connection.remove_column(table_name.to_sym, column_name.to_sym)
    end
  end
end
