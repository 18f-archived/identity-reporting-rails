# rubocop:disable Rails/CreateTableWithTimestamps
class CreateIaaGtc < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.iaa_gtcs', if_not_exists: true do |t|
      t.string 'gtc_number'
      t.integer 'mod_number', default: 0, null: false
      t.date 'start_date'
      t.date 'end_date'
      t.decimal 'estimated_amount', precision: 12, scale: 2
      t.bigint 'partner_account_id'
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
