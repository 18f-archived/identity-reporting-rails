require 'schema_table_service'
class ExtractorRowCheckerEnqueueJob < ApplicationJob
  queue_as :default

  def perform
    schema_table_service = SchemaTableService.generate_schema_table_hash
    schema_table_service.each do |schema_name, tables|
      tables.each do |table_name|
        begin
          LogsColumnExtractorJob.perform_later(table_name) if schema_name == 'logs'
          DuplicateRowCheckerJob.perform_later(table_name, schema_name)
        rescue StandardError => e
          Rails.logger.error "ExtractorRowCheckerEnqueueJob:Failed to enqueue job for table
#{table_name} in schema #{schema_name}: #{e.message}"
        end
      end
    end
  end
end
