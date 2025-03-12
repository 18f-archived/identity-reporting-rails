# rubocop:disable Rails/CreateTableWithTimestamps
class CreatePartnerAccountStatus < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.partner_account_statuses', if_not_exists: true do |t|
      t.string 'name', null: false
      t.integer 'order'
      t.string 'partner_name'
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
