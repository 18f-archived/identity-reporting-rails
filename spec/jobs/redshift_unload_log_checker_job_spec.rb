require 'rails_helper'

RSpec.describe RedshiftUnloadLogCheckerJob, type: :job do
  before do
    allow(Rails.logger).to receive(:info)
    allow(Identity::Hostdata.config).to receive(:unload_line_count_threshold).and_return(100)
  end

  describe '#perform' do
    context 'when unload logs are found above threshold' do
      let(:expected_log) do
        {
          job: 'RedshiftUnloadLogCheckerJob',
          success: false,
          message: 'RedshiftUnloadLogCheckerJob: Found 2 unload logs above threshold',
          data: [{ 'userid' => 1,
                   'starttime' => Time.zone.now.utc.strftime('%Y-%m-%d %H:%M'),
                   'endtime' => Time.zone.now.utc.strftime('%Y-%m-%d %H:%M'),
                   's3_path' => 's3://bucket/folder/file.csv',
                   'query_id' => 1,
                   'line_count' => 150,
                 },
                 { 'userid' => 1,
                   'starttime' => Time.zone.now.utc.strftime('%Y-%m-%d %H:%M'),
                   'endtime' => Time.zone.now.utc.strftime('%Y-%m-%d %H:%M'),
                   's3_path' => 's3://bucket/folder/file.csv',
                   'query_id' => 2,
                   'line_count' => 250,
                  }],
        }.to_json
      end

      before do
        FactoryBot.create(:stl_unload_log, line_count: 150, query: 1)
        FactoryBot.create(:stl_unload_log, line_count: 250, query: 2)
      end

      it 'logs a message indicating logs are found' do
        described_class.perform_now

        expect(Rails.logger).to have_received(:info).with(expected_log)
      end
    end

    context 'when no unload logs are found above threshold' do
      let(:expected_log) do
        {
          job: 'RedshiftUnloadLogCheckerJob',
          success: true,
          message: 'RedshiftUnloadLogCheckerJob: No unload logs found above threshold',
        }.to_json
      end

      before do
        FactoryBot.create(:stl_unload_log, transfer_size: 0, line_count: 1)
      end

      it 'logs a message indicating no logs are found' do
        described_class.perform_now

        expect(Rails.logger).to have_received(:info).with(expected_log)
      end
    end
  end
end
