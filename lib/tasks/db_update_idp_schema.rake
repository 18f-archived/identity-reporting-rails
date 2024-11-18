# lib/tasks/db_update_idp_schema.rake

# frozen_string_literal: true

require 'redshift_schema_updater'

namespace :db do
  desc 'Sync the schema of tables in the idp schema with the schema defined in the YAML file'
  task update_idp_schema: :environment do
    env = ENV['RAILS_ENV']
    unless env
      puts 'RAILS_ENV environment variable is not set'
      exit 1
    end

    schema_updater = RedshiftSchemaUpdater.new('idp')
    local_devops_path = IdentityConfig::REPO_PATHS[:identity_devops]
    schema_updater.update_schema_from_yaml(
      "#{local_devops_path}/terraform/modules/data_warehouse_export/dms-filter-columns-transformation-rules.yml", # rubocop:disable Layout/LineLength
    )
  end
end
