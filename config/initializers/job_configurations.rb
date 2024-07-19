cron_5m = '0/5 * * * *'
cron_2m = '0/2 * * * *'
cron_1d = '0 0 * * *'
table_names = ['events', 'production']

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
      logs_column_extractor_job: {
        class: 'LogsColumnExtractorJob',
        cron: cron_1d,
      },
      # Queue duplicate row checker job to GoodJob
      duplicate_row_checker_job: {
        class: 'DuplicateRowCheckerJob',
        cron: cron_1d,
      },
    }.compact
    # dynamic job scheduling
    table_names.each do |table_name|
      config.good_job.cron[:"logs_column_extractor_job_#{table_name}"] = {
        class: 'LogsColumnExtractorJob',
        cron: cron_2m,
        args: -> { [table_name] },
      }
    end
  end

  Rails.logger.info 'job_configurations: jobs scheduled with good_job.cron'
end
