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

      it 'returns the duplicate articles' do
        duplicates = idp_job.perform('articles', 'idp')
        expect(duplicates).not_to be_empty
        expect(duplicates.first['id']).to eq(1)
      end
    end

    context 'when there are duplicate events' do
      before do
        2.times { FactoryBot.create(:event, message: { text: 'Duplicate Message' }.to_json) }
      end

      it 'returns the duplicate events' do
        duplicates = logs_job.perform('events', 'logs')
        expect(duplicates).not_to be_empty
        expect(duplicates.first['message']).to eq({ 'text' => 'Duplicate Message' }.to_json)
      end
    end

    context 'when there are no duplicate articles' do
      before do
        FactoryBot.create(:article, id: 1, title: 'Unique Title', content: 'Unique Content')
      end

      it 'returns an empty array' do
        duplicates = idp_job.perform('articles', 'idp')
        expect(duplicates).to be_empty
      end
    end

    context 'when there are no duplicate events' do
      before do
        FactoryBot.create(:event, message: { text: 'Unique Message' }.to_json)
      end

      it 'returns an empty array' do
        duplicates = logs_job.perform('events', 'logs')
        expect(duplicates).to be_empty
      end
    end
  end
end
