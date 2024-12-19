class CreateStlUnloadLogTable < ActiveRecord::Migration[7.1]
  def change
    create_table 'stl_unload_log', if_not_exists: true, id: false do |t|
      t.integer :userid
      t.integer :query
      t.integer :pid
      t.string :path
      t.timestamp :start_time
      t.timestamp :end_time
      t.bigint :line_count
      t.bigint :transfer_size
      t.string :file_format
    end
  end
end
