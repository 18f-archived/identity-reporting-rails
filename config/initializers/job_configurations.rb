require 'schema_table_service'

cron_5m = '0/5 * * * *'
cron_2m = '0/2 * * * *'
cron_1d = '0 0 * * *'

schema_table_service = SchemaTableService.new
schema_table_hash = schema_table_service.generate_schema_table_hash

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
    }

    schema_table_hash.each do |schema_name, tables|
      tables.each do |table_name, uniq_id|
        job_class = schema_name == 'logs' ? 'LogsColumnExtractorJob' : 'DuplicateRowCheckerJob'
        job_name = schema_name == 'logs' ? :"logs_column_extractor_job_#{table_name}" : :"duplicate_row_checker_job_#{table_name}_#{schema_name}"

        config.good_job.cron[job_name] = {
          class: job_class,
          cron: cron_5m,
          args: -> { schema_name == 'logs' ? [table_name] : [table_name, schema_name] },
        }
      end
    end

    Rails.logger.info 'job_configurations: jobs scheduled with good_job.cron'
  end
end
