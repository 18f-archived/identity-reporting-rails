# lib/tasks/db_create_with_exceptions.rake

# frozen_string_literal: true

require 'active_record'
require 'active_support/configuration_file'
require 'active_support/deprecation'

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

namespace :db do
  # Define task to create all databases except the specified ones
  desc 'Create all databases except the specified one in production'
  task create_with_exceptions: :environment do
    # Ensure the RAILS_ENV environment variable is set
    env = ENV['RAILS_ENV']
    unless env
      puts 'RAILS_ENV environment variable is not set'
      exit 1
    end

    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      if name in ['data_warehouse']
        puts "Skipping creation of database: #{name}"
        next
      end

      desc "Create #{name} database for current environment"
      task name => :load_config do
        db_config = ActiveRecord::Base.configurations.configs_for(env_name: env, name: name)
        ActiveRecord::Tasks::DatabaseTasks.create(db_config)
        puts "Created database: #{db_config.database}"
      end
    end
  end
end
