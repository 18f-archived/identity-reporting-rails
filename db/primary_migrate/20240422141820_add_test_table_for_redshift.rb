class AddTestTableForRedshift < ActiveRecord::Migration[7.1]
  def change
    create_table :test_redshifts do |t|
      t.text :name

      t.timestamps
    end
  end
end
