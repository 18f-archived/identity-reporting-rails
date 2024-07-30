require 'yaml'

class SchemaTableService
  def initialize
    require_dependency 'data_warehouse_application_record'
  end

  # Generate a hash of schema names and their tables with unique identifier columns.
  def generate_schema_table_hash
    schema_table_hash = {}
    target_schemas = DataWarehouseApplicationRecord.connection.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'public', 'pg_toast')").values.flatten
    # target_schemas = ['logs', 'idp']
    target_schemas.each do |schema_name|
      schema_table_hash[schema_name] = fetch_tables_for_schema(schema_name)
    end
    schema_table_hash
  end

  def table_exists?(table_name)
    DataWarehouseApplicationRecord.connection.table_exists?(table_name)
  end

  # Fetch tables for a given schema and return a hash with table names and unique identifier columns
  def fetch_tables_for_schema(schema_name)
    table_hash = {}
    tables = fetch_tables(schema_name)
    tables.each do |table_name|
      next if table_name.start_with?('unextracted_')
      uniq_by = determine_unique_identifier(schema_name, table_name)
      table_hash[table_name] = uniq_by
    end
    table_hash
  end

  # Fetch table names for a given schema.
  def fetch_tables(schema_name)
    query = "SELECT table_name FROM information_schema.tables WHERE table_schema = '#{schema_name}'"
    result = DataWarehouseApplicationRecord.connection.execute(query)
    # result.rows.flatten
    result.values.flatten
  end

  # Determine the unique identifier column ('id' or 'uuid') for a given table.
  def determine_unique_identifier(schema_name, table_name)
    columns = DataWarehouseApplicationRecord.connection.columns("#{schema_name}.#{table_name}")
    columns.any? { |c| c.name == 'id' } ? 'id' : 'uuid'
  end
end
