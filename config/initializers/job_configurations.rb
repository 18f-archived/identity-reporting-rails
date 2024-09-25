cron_30m = '*/30 * * * *'
cron_5m = '0/5 * * * *'
cron_1d = '0 6 * * *' # 6:00am UTC or 2:00am EST

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
      # Queue redshift new user detection job to GoodJob
      redshift_new_user_detection_job: {
        class: 'RedshiftUnexpectedUserDetectionJob',
        cron: '2-59/2 * * * *',
        # runs every 5 minutes starting at 2 minutes past the hour to allow the user sync script
        # to complete at the top of the hour
      },
      # Queue schema service job to GoodJob
      extractor_row_checker_enqueue_job: {
        class: 'ExtractorRowCheckerEnqueueJob',
        cron: cron_1d,
      },
    }
    Rails.logger.info 'job_configurations: jobs scheduled with good_job.cron'
  end
end
