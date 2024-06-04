class AddColumnsToEventsAndProductionTable < ActiveRecord::Migration[7.1]
  def change
    # Add columns to 'logs.events' table
    add_column 'logs.events', :cloudwatch_timestamp, :timestamp
    add_column 'logs.events', :id, :string
    add_column 'logs.events', :name, :string
    add_column 'logs.events', :time, :string
    add_column 'logs.events', :visitor_id, :string
    add_column 'logs.events', :visit_id, :string
    add_column 'logs.events', :log_filename, :string
    add_column 'logs.events', :new_event, :boolean, default: false, null: false
    add_column 'logs.events', :path, :string
    add_column 'logs.events', :user_id, :string
    add_column 'logs.events', :locale, :string
    add_column 'logs.events', :user_ip, :string
    add_column 'logs.events', :hostname, :string
    add_column 'logs.events', :pid, :integer
    add_column 'logs.events', :service_provider, :string
    add_column 'logs.events', :trace_id, :string
    add_column 'logs.events', :git_sha, :string
    add_column 'logs.events', :git_branch, :string
    add_column 'logs.events', :user_agent, :string
    add_column 'logs.events', :browser_name, :string
    add_column 'logs.events', :browser_version, :string
    add_column 'logs.events', :browser_platform_name, :string
    add_column 'logs.events', :browser_platform_version, :string
    add_column 'logs.events', :browser_device_name, :string
    add_column 'logs.events', :browser_mobile, :boolean, default: false, null: false
    add_column 'logs.events', :browser_bot, :boolean, default: false, null: false
    add_column 'logs.events', :success, :boolean, default: false, null: false

    # Add columns to 'logs.production' table
    add_column 'logs.productions', :cloudwatch_timestamp, :timestamp
    add_column 'logs.productions', :uuid, :string
    add_column 'logs.productions', :method, :string
    add_column 'logs.productions', :path, :string
    add_column 'logs.productions', :format, :string
    add_column 'logs.productions', :controller, :string
    add_column 'logs.productions', :action, :string
    add_column 'logs.productions', :status, :string
    add_column 'logs.productions', :duration, :string
    add_column 'logs.productions', :git_sha, :string
    add_column 'logs.productions', :git_branch, :string
    add_column 'logs.productions', :pid, :integer, null: true
    add_column 'logs.productions', :user_agent, :string
    add_column 'logs.productions', :ip, :string
    add_column 'logs.productions', :host, :string
    add_column 'logs.productions', :trace_id, :string
  end
end
