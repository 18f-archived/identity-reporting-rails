class SetPrimaryKeysEventsAndProduction < ActiveRecord::Migration[7.1]
  def change
    unless connection.adapter_name.downcase.include?('redshift')
      # Add primary key to 'logs.events' table
      execute 'ALTER TABLE logs.events ADD PRIMARY KEY (id);'
      # Add primary key to 'logs.events' table
      execute 'ALTER TABLE logs.production ADD PRIMARY KEY (uuid);'
    end
  end
end
