require 'rake'
require 'schema_table_service'

cron_5m = '0/5 * * * *'
cron_2m = '0/2 * * * *'
cron_1d = '0 0 * * *'
table_names = ['events', 'production']

Rake.application.init
Rake.application.load_rakefile

# Rake::Task['db:schema_table_list'].invoke
schema_table_service = SchemaTableService.new
schema_table_hash = schema_table_service.generate_schema_table_hash
# schema_table_hash.each do |schema_name, tables|
#   tables.each do |table_name, uniq_by|
#     Rake::Task["db:logs_column_extractor_job_#{table_name}"].invoke
#   end
# end

if defined?(Rails::Console)
  Rails.logger.info 'job_configurations: console detected, skipping schedule'
else
  Rails.application.configure do
    config.good_job.cron = {
      # Queue heartbeat job to GoodJob
      heartbeat_job: {
        class: 'HeartbeatJob',
        cron: cron_5m,
      },
      # Queue logs column extractor job to GoodJob
      # log_tables_column_extractor_job: {
      #   class: 'LogsColumnExtractorJob',
      #   cron: cron_1d,
      # },
      # Queue duplicate row checker job to GoodJob
      duplicate_row_checker_job: {
        class: 'DuplicateRowCheckerJob',
        cron: cron_1d,
      },
    }
    schema_table_hash.each do |schema_name, tables|
      tables.each do |table_name, uniq_id|
        config.good_job.cron[:"logs_column_extractor_job_#{table_name}"] = {
          class: 'LogsColumnExtractorJob',
          cron: cron_2m,
          args: -> { [table_name] },
        }
      end
    end
  end
  Rails.logger.info 'job_configurations: jobs scheduled with good_job.cron'
end
