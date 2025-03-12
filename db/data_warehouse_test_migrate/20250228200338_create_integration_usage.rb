# rubocop:disable Rails/CreateTableWithTimestamps
class CreateIntegrationUsage < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.integration_usages', if_not_exists: true do |t|
      t.bigint 'iaa_order_id'
      t.bigint 'integration_id'
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
