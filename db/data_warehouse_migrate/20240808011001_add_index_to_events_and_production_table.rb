class AddIndexToEventsAndProductionTable < ActiveRecord::Migration[7.1]
  def change
    unless connection.adapter_name.downcase.include?('redshift')
      # Add index to 'logs.events' table
      add_index 'logs.events', :id, name: 'index_events_on_id', unique: false
      
      # Add index to 'logs.production' table
      add_index 'logs.production', :uuid, name: 'index_production_on_uuid', unique: false
    end
  end
end
