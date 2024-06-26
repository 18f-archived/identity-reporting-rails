cron_5m = '0/5 * * * *'
cron_1d = '0 0 * * *'

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
      log_tables_column_extractor_job: {
        class: 'LogsColumnExtractorJob',
        cron: cron_1d,
      },
    }
  end
  Rails.logger.info 'job_configurations: jobs scheduled with good_job.cron'
end
