class CreateEventsAndProductionTable < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up { execute 'CREATE SCHEMA IF NOT EXISTS logs' }
      dir.down { execute 'DROP SCHEMA IF EXISTS logs' }
    end

    # Define the tables to be created
    tables = ['unextracted_events', 'unextracted_production', 'events', 'production']

    tables.each do |table|
      if connection.adapter_name.downcase.include?('redshift')
        execute <<-SQL
          CREATE TABLE IF NOT EXISTS logs.#{table} (
            message SUPER,
            cloudwatch_timestamp TIMESTAMP
          );
        SQL
      else
        create_table "logs.#{table}", if_not_exists: true, id: false do |t|
          t.jsonb :message
          t.timestamp :cloudwatch_timestamp
        end
      end
    end
  end
end
