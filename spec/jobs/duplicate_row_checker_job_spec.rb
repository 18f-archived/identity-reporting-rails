require 'rails_helper'
require 'factory_bot'

RSpec.describe DuplicateRowCheckerJob, type: :job do
  let(:idp_job) { DuplicateRowCheckerJob.new }
  let(:logs_job) { DuplicateRowCheckerJob.new }

  describe '#perform' do
    context 'when there are duplicate articles' do
      before do
        2.times do
          FactoryBot.create(:article, id: 1, title: 'Duplicate Title', content: 'Duplicate Content')
        end
      end

      it 'logs a warning' do
        expected_message = 'DuplicateRowCheckerJob: Found 1 duplicate(s) in "idp"."articles"'
        expect(Rails.logger).to receive(:warn).with(expected_message)
        idp_job.perform(table_name: 'articles', schema_name: 'idp', uniq_by: 'id')
      end
    end

    context 'when there are duplicate events' do
      before do
        2.times do |i|
          FactoryBot.create(
            :event,
            message: { id: 1, text: 'Duplicate Message' }.to_json,
            id: i.to_s,
          )
        end
      end

      it 'logs a warning' do
        expected_message = 'DuplicateRowCheckerJob: Found 1 duplicate(s) in "logs"."events"'
        expect(Rails.logger).to receive(:warn).with(expected_message)
        logs_job.perform(table_name: 'events', schema_name: 'logs', uniq_by: 'message')
      end
    end

    context 'when there are no duplicate articles' do
      before do
        FactoryBot.create(:article, id: 1, title: 'Unique Title', content: 'Unique Content')
      end

      it 'does not log a warning' do
        expect(Rails.logger).not_to receive(:warn)
        idp_job.perform(table_name: 'articles', schema_name: 'idp', uniq_by: 'id')
      end
    end

    context 'when there are no duplicate events' do
      before do
        FactoryBot.create(:event, message: { id: 1, text: 'Unique Message' }.to_json, id: '1')
      end

      it 'does not log a warning' do
        expect(Rails.logger).not_to receive(:warn)
        logs_job.perform(table_name: 'events', schema_name: 'logs', uniq_by: 'message')
      end
    end
  end
end
