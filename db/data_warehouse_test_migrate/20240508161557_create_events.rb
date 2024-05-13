class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up { execute 'CREATE SCHEMA IF NOT EXISTS logs' }
      dir.down { execute 'DROP SCHEMA IF EXISTS logs' }
    end

    create_table 'logs.events', if_not_exists: true, id: false do |t|
      t.text :message
      t.timestamp :timestamp
    end
  end
end
