class RenameEventsTimestampColumn < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up { execute 'ALTER TABLE logs.events RENAME COLUMN timestamp to cloudwatch_timestamp;' }
      dir.down do
        execute 'ALTER TABLE logs.events RENAME COLUMN cloudwatch_timestamp to timestamp;'
      end
    end
  end
end
