# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_05_30_185518) do
  create_schema 'logs'

  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'events', id: false, force: :cascade do |t|
    t.jsonb 'message'
    t.datetime 'cloudwatch_timestamp', precision: nil
    t.string 'id'
    t.string 'name'
    t.datetime 'time', precision: nil
    t.string 'visitor_id'
    t.string 'visit_id'
    t.string 'log_filename'
    t.boolean 'new_event'
    t.string 'path'
    t.string 'user_id'
    t.string 'locale'
    t.string 'user_ip'
    t.string 'hostname'
    t.integer 'pid'
    t.string 'service_provider'
    t.string 'trace_id'
    t.string 'git_sha'
    t.string 'git_branch'
    t.string 'user_agent', limit: 512
    t.string 'browser_name'
    t.string 'browser_version'
    t.string 'browser_platform_name'
    t.string 'browser_platform_version'
    t.string 'browser_device_name'
    t.boolean 'browser_mobile'
    t.boolean 'browser_bot'
    t.boolean 'success'
  end

  create_table 'production', id: false, force: :cascade do |t|
    t.jsonb 'message'
    t.datetime 'cloudwatch_timestamp', precision: nil
    t.string 'uuid'
    t.string 'method'
    t.string 'path'
    t.string 'format'
    t.string 'controller'
    t.string 'action'
    t.integer 'status'
    t.float 'duration'
    t.string 'git_sha'
    t.string 'git_branch'
    t.datetime 'timestamp', precision: nil
    t.integer 'pid'
    t.string 'user_agent', limit: 512
    t.string 'ip'
    t.string 'host'
    t.string 'trace_id'
  end

  create_table 'unextracted_events', id: false, force: :cascade do |t|
    t.jsonb 'message'
    t.datetime 'cloudwatch_timestamp', precision: nil
  end

  create_table 'unextracted_production', id: false, force: :cascade do |t|
    t.jsonb 'message'
    t.datetime 'cloudwatch_timestamp', precision: nil
  end
end
