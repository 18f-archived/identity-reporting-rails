cron_30m = '*/30 * * * *'
cron_5m = '0/5 * * * *'
cron_6h = '0 */6 * * *'

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
      # Queue data freshness check job for production table to GoodJob
      data_freshness_job: {
        class: 'DataFreshnessJob',
        cron: cron_30m,
      },
      # Queue schema service job to GoodJob
      extractor_row_checker_enqueue_job: {
        class: 'ExtractorRowCheckerEnqueueJob',
        cron: cron_6h,
      },
    }
    Rails.logger.info 'job_configurations: jobs scheduled with good_job.cron'
  end
end
