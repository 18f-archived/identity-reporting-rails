# rubocop:disable Rails/CreateTableWithTimestamps
class CreateIaaOrder < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.iaa_orders', if_not_exists: true do |t|
      t.integer 'order_number'
      t.integer 'mod_number', default: 0
      t.date 'start_date'
      t.date 'end_date'
      t.decimal 'estimated_amount', precision: 12, scale: 2
      t.integer 'pricing_model', default: 2
      t.bigint 'iaa_gtc_id'
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
