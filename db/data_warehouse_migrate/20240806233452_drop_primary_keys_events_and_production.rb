class DropPrimaryKeysEventsAndProduction < ActiveRecord::Migration[7.1]
  def change
    unless connection.adapter_name.downcase.include?('redshift')
      # Drop primary key from 'logs.events' table
      execute 'ALTER TABLE logs.events DROP CONSTRAINT events_pkey;'
      # Drop primary key from 'logs.production' table
      execute 'ALTER TABLE logs.production DROP CONSTRAINT production_pkey;'
    end
  end
end
