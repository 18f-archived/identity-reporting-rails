class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    execute "CREATE SCHEMA IF NOT EXISTS logs"

    create_table 'logs.events', if_not_exists: true, id: false do |t|
      t.text :message
      t.timestamp :timestamp
    end
  end
end
