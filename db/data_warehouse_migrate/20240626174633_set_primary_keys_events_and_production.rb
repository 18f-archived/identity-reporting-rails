class SetPrimaryKeysEventsAndProduction < ActiveRecord::Migration[7.1]
  def change
    # Add primary key to 'logs.events' table
    execute 'ALTER TABLE logs.events ADD PRIMARY KEY (id);'
    # Add primary key to 'logs.events' table
    execute 'ALTER TABLE logs.production ADD PRIMARY KEY (uuid);'
  end
end
