require 'rails_helper'
require 'factory_bot'

RSpec.describe LogsColumnExtractorJob, type: :job do
  let(:logs_job) { LogsColumnExtractorJob.new }

  describe '#perform' do
    context 'when target table is events' do
      before do
        FactoryBot.create(
        :unextracted_event, 
        cloudwatch_timestamp: '2024-05-29T20:34:17.933Z', 
        message: {
          "name": "Sign in page visited",
          "properties":{
            "event_properties":{
              "flash": nil
              },
              "new_event": true,
              "path": "/",
              "session_duration":0.000758357,
              "user_id": "anonymous-uuid",
              "locale": "en",
              "user_ip": "50.116.19.65",
              "hostname": "idp.agnes.identitysandbox.gov",
              "pid":10330,
              "service_provider": nil,
              "trace_id": "Root=1-66579145-6437417b34c76feb7f9e767b",
              "git_sha": "78b1b6bb",
              "git_branch": "main","user_agent": 
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
              "browser_name": "Chrome",
              "browser_version": "101.0.4951.61",
              "browser_platform_name": "Windows",
              "browser_platform_version": "10.0",
              "browser_device_name": "Unknown",
              "browser_mobile": false,
              "browser_bot": false
            },
            "time": "2024-05-29T20:34:13.334Z",
            "id": "dea36747-e42e-4e20-acc0-880c2c722e41",
            "visitor_id": "c41b33a5-f48b-42b9-aabd-617cec0db776",
            "visit_id": "4f67f9da-2dc3-4049-86ce-49f005441091",
            "log_filename": "events.log"
            }.to_json
        ) 
      end

      it 'confirm the column extraction query is valid' do
        expected_events_query = <<~SQL
          BEGIN;
          LOCK logs.unextracted_events;
          CREATE TEMP TABLE unextracted_events_temp AS
          SELECT 
            message
            , cloudwatch_timestamp
            , message.id::VARCHAR 
            , message.name::VARCHAR 
            , message.time::TIMESTAMP 
            , message.visitor_id::VARCHAR 
            , message.visit_id::VARCHAR
            , message.log_filename::VARCHAR 
            , message.properties.new_event::BOOLEAN 
            , message.properties.path::VARCHAR(12000) 
            , message.properties.user_id::VARCHAR 
            , message.properties.locale::VARCHAR 
            , message.properties.user_ip::VARCHAR 
            , message.properties.hostname::VARCHAR 
            , message.properties.pid::INTEGER 
            , message.properties.service_provider::VARCHAR 
            , message.properties.trace_id::VARCHAR 
            , message.properties.git_sha::VARCHAR 
            , message.properties.git_branch::VARCHAR 
            , message.properties.user_agent::VARCHAR(12000) 
            , message.properties.browser_name::VARCHAR 
            , message.properties.browser_version::VARCHAR 
            , message.properties.browswer_platform_name::VARCHAR
            , message.properties.browser_platform_version::VARCHAR 
            , message.properties.browser_device_name::VARCHAR 
            , message.properties.browser_mobile::BOOLEAN 
            , message.properties.browser_bot::BOOLEAN 
            , message.properties.event_properties.success::BOOLEAN
          FROM logs.unextracted_events;
          WITH duplicate_rows as (
              SELECT id
              , ROW_NUMBER() OVER (PARTITION BY id ORDER BY cloudwatch_timestamp desc) as row_num
              FROM unextracted_events_temp
          )
          DELETE FROM unextracted_events_temp
          USING duplicate_rows
          WHERE duplicate_rows.id = unextracted_events_temp.id and duplicate_rows.row_num > 1;
          MERGE INTO logs.events
          USING unextracted_events_temp
          ON logs.events.id = unextracted_events_temp.id
          REMOVE DUPLICATES;
          TRUNCATE logs.unextracted_events;
          COMMIT;
        SQL
        logs_job.perform(target_table_name: 'events')
        expect(logs_job.query.squish).to eq(expected_events_query.squish)
      end
    end

    context 'when target table is production' do
      it 'confirm the column extraction query is valid' do
        expected_production_query = <<~SQL
          BEGIN;
          LOCK logs.unextracted_production;
          CREATE TEMP TABLE unextracted_production_temp AS
          SELECT
            message
            , cloudwatch_timestamp
            , message.uuid::VARCHAR
            , message.method::VARCHAR
            , message.path::VARCHAR(12000)
            , message.format::VARCHAR
            , message.controller::VARCHAR
            , message.action::VARCHAR
            , message.status::INTEGER
            , message.duration::FLOAT
            , message.git_sha::VARCHAR
            , message.git_branch::VARCHAR
            , message.timestamp::TIMESTAMP
            , message.pid::INTEGER
            , message.user_agent::VARCHAR(12000)
            , message.ip::VARCHAR
            , message.host::VARCHAR
            , message.trace_id::VARCHAR
          FROM logs.unextracted_production;
          WITH duplicate_rows as (
              SELECT uuid
              , ROW_NUMBER() OVER (PARTITION BY uuid ORDER BY cloudwatch_timestamp desc) as row_num
              FROM unextracted_production_temp
          )
          DELETE FROM unextracted_production_temp
          USING duplicate_rows
          WHERE duplicate_rows.uuid = unextracted_production_temp.uuid and duplicate_rows.row_num > 1;
          MERGE INTO logs.production
          USING unextracted_production_temp
          ON logs.production.uuid = unextracted_production_temp.uuid
          REMOVE DUPLICATES;
          TRUNCATE logs.unextracted_production;
          COMMIT;
        SQL
        logs_job.perform(target_table_name: 'production')
        expect(logs_job.query.squish).to eq(expected_production_query.squish)
      end
    end
  end
end
