# rubocop:disable Rails/CreateTableWithTimestamps
class CreateIntegrationStatuses < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.integration_statuses', if_not_exists: true do |t|
      t.string 'name', null: false, index: true
      t.integer 'order', null: false, index: true
      t.string 'partner_name'
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
