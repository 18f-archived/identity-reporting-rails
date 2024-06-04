class CreateEventsAndProductionTable < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up { execute 'CREATE SCHEMA IF NOT EXISTS logs' }
      dir.down { execute 'DROP SCHEMA IF EXISTS logs' }
    end

    # Check if logs.unextracted_events table exists, if not, create it
    create_table 'logs.unextracted_events', if_not_exists: true, id: false do |t|
      if connection.adapter_name.downcase.include? 'redshift'
        t.column :message, :super
      else
        t.jsonb :message
      end
      t.timestamp :cloudwatch_timestamp
    end

    # Check if logs.unextracted_production table exists, if not, create it
    create_table 'logs.unextracted_production', if_not_exists: true, id: false do |t|
      if connection.adapter_name.downcase.include? 'redshift'
        t.column :message, :super
      else
        t.jsonb :message
      end
      t.timestamp :cloudwatch_timestamp
    end

    # Check if logs.events table exists, if not, create it
    create_table 'logs.events', if_not_exists: true, id: false do |t|
      if connection.adapter_name.downcase.include? 'redshift'
        t.column :message, :super
      else
        t.jsonb :message
      end
      t.timestamp :cloudwatch_timestamp
    end

    # Check if logs.production table exists, if not, create it
    create_table 'logs.production', if_not_exists: true, id: false do |t|
      if connection.adapter_name.downcase.include? 'redshift'
        t.column :message, :super
      else
        t.jsonb :message
      end
      t.timestamp :cloudwatch_timestamp
    end
  end
end
