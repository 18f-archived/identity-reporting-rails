# rubocop:disable Rails/CreateTableWithTimestamps
class CreatePartnerAccount < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.partner_accounts', if_not_exists: true do |t|
      t.string :name, null: false
      t.text :description
      t.string :requesting_agency, null: false
      t.date :became_partner
      t.bigint :agency_id
      t.bigint :partner_account_status_id
      t.bigint :crm_id
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
