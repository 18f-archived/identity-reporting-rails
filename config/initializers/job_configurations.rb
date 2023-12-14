if defined?(Rails::Console)
  Rails.logger.info 'job_configurations: console detected, skipping schedule'
else
  Rails.application.configure do
    config.good_job.cron = {}
  end
  Rails.logger.info 'job_configurations: jobs scheduled with good_job.cron'
end
