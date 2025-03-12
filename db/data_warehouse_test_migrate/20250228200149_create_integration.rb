# rubocop:disable Rails/CreateTableWithTimestamps
class CreateIntegration < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.integrations', if_not_exists: true do |t|
      t.string 'issuer'
      t.string 'name'
      t.integer 'dashboard_identifier'
      t.bigint 'partner_account_id'
      t.bigint 'integration_status_id'
      t.bigint 'service_provider_id'
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
