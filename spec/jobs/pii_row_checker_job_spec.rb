require 'rails_helper'
require 'factory_bot'

RSpec.describe PiiRowCheckerJob, type: :job do
  let(:logs_job) { PiiRowCheckerJob.new }
  let(:uuids) { ['07324b45-e043-45cd-8d17-33e8cc8c54e0', '07324b45-e043-45cd-8d17-33e8cc8c54e1'] }

  describe '#perform' do
    context 'when target table name is not recognized' do
      it 'confirm the perform function fails with exception' do
        msg = 'Invalid target table name: random_name'
        expect { logs_job.perform('random_name') }.to raise_error(msg)
      end
    end

    context 'when target table is unextracted_events' do
      let(:test_pattern) { 'WWEEE EWEWEWE' }
      before do
        uuids.each do |uuid|
          FactoryBot.create(
            :unextracted_event,
            cloudwatch_timestamp: '2024-05-29T20:34:17.933Z',
            message: {
              name: 'Sign in page visited',
              properties: {
                event_properties: {
                  flash: nil,
                },
                new_event: true,
                path: '/',
                session_duration: 0.000758357,
                user_id: 'anonymous-uuid',
                browser_device_name: test_pattern,
                browser_mobile: false,
                browser_bot: false,
              },
              time: '2024-05-29T20:34:13.334Z',
              id: uuid,
              visitor_id: 'c41b33a5-f48b-42b9-aabd-617cec0db776',
              visit_id: '4f67f9da-2dc3-4049-86ce-49f005441091',
              log_filename: 'events.log',
            },
          )
        end
      end
      context 'when full name ' do
        it 'logs warning when pii pattern with upper case' do
          expected_message = 'PiiRowCheckerJob: Found fullname_with_upper_Case PII in logs.unextracted_events'
          expect(Rails.logger).to receive(:warn).with(expected_message)
          logs_job.perform('unextracted_events')
        end
      end
      context 'when dob dash' do
        let(:test_pattern) { '01-01-2024' }
        it 'logs warning when pii pattern with dob dash' do
          expected_message = 'PiiRowCheckerJob: Found dob_with_dash PII in logs.unextracted_events'
          expect(Rails.logger).to receive(:warn).with(expected_message)
          logs_job.perform('unextracted_events')
        end
      end
      context 'when dob slash' do
        let(:test_pattern) { '01/01/2024' }
        it 'logs warning when pii pattern with dob dash' do
          expected_message = 'PiiRowCheckerJob: Found dob_with_slash PII in logs.unextracted_events'
          expect(Rails.logger).to receive(:warn).with(expected_message)
          logs_job.perform('unextracted_events')
        end
      end
      context 'when address' do
        let(:test_pattern) {  '789 some rd, town,' }
        it 'logs warning when pii pattern address with out zipcode' do
          expected_message = 'PiiRowCheckerJob: Found address_without_zipcode PII in logs.unextracted_events'
          expect(Rails.logger).to receive(:warn).with(expected_message)
          logs_job.perform('unextracted_events')
        end
      end
    end

    context 'when target table is unextracted_production' do
      let(:test_pattern) { '345-567-7890' }
      before do
        uuids.each do |uuid|
          FactoryBot.create(
            :unextracted_production,
            cloudwatch_timestamp: '2024-04-23T15:07:11.896Z',
            message: {
              method: 'GET',
              path: '/api/health',
              format: 'html',
              controller: 'Health::HealthController',
              action: 'index',
              status: 200,
              duration: 2.31,
              git_sha: '712c0ec1',
              git_branch: 'main',
              timestamp: '2024-04-23T15:07:11Z',
              uuid: uuid,
              pid: 8932,
              user_agent: test_pattern,
              ip: '100.106.65.246',
              host: '100.106.122.235',
              trace_id: nil,
            },
          )
        end
      end
      context 'when phonenumber' do
        it 'log warning with pii phonenumber pattern' do
          expected_message = 'PiiRowCheckerJob: Found phone_number PII in logs.unextracted_production'
          expect(Rails.logger).to receive(:warn).with(expected_message)
          logs_job.perform('unextracted_production')
        end
      end
      context 'when there is no pii' do
        let(:test_pattern) { 'ELB-HealthChecker/2.0' }
        it 'log info' do
          expect(Rails.logger).not_to receive(:warn)
          logs_job.perform('unextracted_production')
        end
      end
    end
  end
end
