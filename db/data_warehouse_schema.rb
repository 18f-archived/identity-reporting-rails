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

ActiveRecord::Schema[7.1].define(version: 2024_11_04_093856) do
  create_schema 'idp'
  create_schema 'logs'
  create_schema 'system_tables'

  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'stl_query', id: false, force: :cascade do |t|
    t.integer 'userid'
    t.integer 'query'
    t.string 'label'
    t.bigint 'xid'
    t.integer 'pid'
    t.string 'database'
    t.string 'querytxt'
    t.datetime 'starttime', precision: nil
    t.datetime 'endtime', precision: nil
    t.integer 'aborted'
    t.integer 'insert_pristine'
    t.integer 'concurency_scalling_status'
  end

  create_table 'production', id: false, force: :cascade do |t|
    t.jsonb 'message'
    t.datetime 'cloudwatch_timestamp', precision: nil
    t.string 'uuid', null: false
    t.string 'method'
    t.string 'path', limit: 12000
    t.string 'format'
    t.string 'controller'
    t.string 'action'
    t.integer 'status'
    t.float 'duration'
    t.string 'git_sha'
    t.string 'git_branch'
    t.datetime 'timestamp', precision: nil
    t.integer 'pid'
    t.string 'user_agent', limit: 12000
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
