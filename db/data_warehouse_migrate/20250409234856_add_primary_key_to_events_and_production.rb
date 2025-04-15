class AddPrimaryKeyToEventsAndProduction < ActiveRecord::Migration[7.2]
  def change
    if connection.adapter_name.downcase.include?('redshift')
      # Add primary key to 'logs.events' table
      execute 'ALTER TABLE logs.events ADD PRIMARY KEY (id);'
      # Add primary key to 'logs.events' table
      execute 'ALTER TABLE logs.production ADD PRIMARY KEY (uuid);'
    end
  end
end
