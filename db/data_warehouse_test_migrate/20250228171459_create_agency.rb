# rubocop:disable Rails/CreateTableWithTimestamps
class CreateAgency < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.agencies', if_not_exists: true do |t|
      t.string :name, null: false
      t.string :abbreviation
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
