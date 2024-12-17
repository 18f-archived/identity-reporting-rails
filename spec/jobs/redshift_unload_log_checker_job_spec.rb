require 'rails_helper'

RSpec.describe RedshiftUnloadLogCheckerJob, type: :job do
  before do
    allow(Rails.logger).to receive(:info)
    allow(Identity::Hostdata.config).to receive(:transfer_size_threshold_in_bytes).and_return(100)
  end

  describe '#perform' do
    context 'when unload logs are found above threshold' do
      let(:expected_log) do
        {
          job: 'RedshiftUnloadLogCheckerJob',
          success: false,
          message: 'RedshiftUnloadLogCheckerJob: Found unload logs above threshold',
          data: [{ 'userid' => 1,
                   'starttime' => Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
                   'endtime' => Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
                   's3_path' => 's3://bucket/folder/file.csv',
                   'query_id' => 1 },
                 { 'userid' => 1,
                   'starttime' => Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
                   'endtime' => Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
                   's3_path' => 's3://bucket/folder/file.csv',
                   'query_id' => 2 }],
        }.to_json
      end

      before do
        FactoryBot.create(:stl_unload_log, transfer_size: 150, line_count: 50, query: 1)
        # FactoryBot.create(:stl_unload_log, transfer_size: 150, line_count: 50, query: 2)
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
