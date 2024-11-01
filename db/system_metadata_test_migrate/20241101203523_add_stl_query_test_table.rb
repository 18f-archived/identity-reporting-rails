class AddStlQueryTestTable < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up { execute 'CREATE SCHEMA IF NOT EXISTS test_pg_catalog' }
      dir.down { execute 'DROP SCHEMA IF EXISTS pg_catalog_test' }
    end

    create_table 'test_pg_catalog.stl_query', if_not_exists: true, id: false do |t|
      t.integer :userid
      t.integer :query
      t.string :label
      t.bigint :xid
      t.integer :pid
      t.string :database
      t.string :querytxt
      t.timestamp :starttime
      t.timestamp :endtime
      t.integer :aborted
      t.integer :insert_pristine
      t.integer :concurency_scalling_status
    end
  end
end
