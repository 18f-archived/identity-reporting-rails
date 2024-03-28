require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/good_job_connection_pool_size'
require_relative '../lib/identity_job_log_subscriber'
require_relative '../lib/identity_config'
require_relative '../lib/version_headers'
require 'identity/logging/railtie'

APP_NAME = 'Identity Reporting Rails'.freeze

module IdentityReportingRails
  class Application < Rails::Application
    if (log_level = ENV['LOGIN_TASK_LOG_LEVEL'])
      Identity::Hostdata.logger.level = log_level
    end

    configuration = Identity::Hostdata::ConfigReader.new(
      app_root: Rails.root,
      logger: Identity::Hostdata.logger,
    ).read_configuration(
      Rails.env, write_copy_to: Rails.root.join('tmp', 'application.yml')
    )
    IdentityConfig.build_store(configuration)

    console do
      if ENV['ALLOW_CONSOLE_DB_WRITE_ACCESS'] != 'true' &&
         IdentityConfig.store.database_readonly_username.present? &&
         IdentityConfig.store.database_readonly_password.present?
        warn <<-EOS.squish
          WARNING: Loading database a configuration with the readonly database user.
          If you wish to make changes to records in the database set
          ALLOW_CONSOLE_DB_WRITE_ACCESS to "true" in the environment
        EOS

        ActiveRecord::Base.establish_connection :read_replica
      end
    end

    config.load_defaults '7.0'
    config.active_record.belongs_to_required_by_default = false
    config.active_job.queue_adapter = :good_job

    FileUtils.mkdir_p(Rails.root.join('log'))
    config.active_job.logger = ActiveSupport::Logger.new(Rails.root.join('log', 'workers.log'))
    config.active_job.logger.formatter = config.log_formatter

    config.good_job.execution_mode = :external
    config.good_job.poll_interval = 5
    config.good_job.enable_cron = true
    config.good_job.max_threads = IdentityConfig.store.good_job_max_threads
    config.good_job.queues = IdentityConfig.store.good_job_queues
    config.good_job.preserve_job_records = false
    config.good_job.enable_listen_notify = false
    config.good_job.queue_select_limit = IdentityConfig.store.good_job_queue_select_limit
    # see config/initializers/job_configurations.rb for cron schedule

    includes_star_queue = config.good_job.queues.split(';').any? do |name_threads|
      name, _threads = name_threads.split(':', 2)
      name == '*'
    end
    raise 'good_job.queues does not contain *, but it should' if !includes_star_queue

    GoodJob.active_record_parent_class = 'WorkerJobApplicationRecord'
    GoodJob.retry_on_unhandled_error = false
    GoodJob.on_thread_error = ->(exception) { NewRelic::Agent.notice_error(exception) }

    config.time_zone = 'UTC'

    routes.default_url_options[:host] = IdentityConfig.store.domain_name
  end
end
