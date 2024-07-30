# lib/tasks/db_schema_table_list.rake

# frozen_string_literal: true

require 'schema_table_service'

namespace :db do
  desc 'Perform operations using SchemaServiceTable'
  task perform_schema_operations: :environment do
    schema_table_service = SchemaTableService.new
    schema_table_service.generate_schema_table_hash
    # puts("schema_table_hash: #{schema_table_hash}\n")

    schema_name = 'logs'
    schema_table_service.fetch_tables_for_schema(schema_name)
    # puts("Tables for schema: #{schema_name} => #{tables_logs}\n")
    # Output the fetched tables
  end
end
