require 'rails_helper'

RSpec.describe ExtractorRowCheckerEnqueueJob, type: :job do
  describe '#perform' do
    let(:schema_table_hash) do
      {
        'logs' => ['events', 'production'],
        'idp' => ['articles'],
      }
    end

    before do
      allow(SchemaTableService).to receive(:generate_schema_table_hash).
        and_return(schema_table_hash)
    end

    it 'enqueues LogsColumnExtractorJob for tables in logs schema' do
      schema_table_hash['logs'].each do |table_name|
        expect(LogsColumnExtractorJob).to receive(:perform_later).with(table_name)
      end

      expect { ExtractorRowCheckerEnqueueJob.new.perform }.not_to raise_error
    end

    it 'enqueues DuplicateRowCheckerJob for all tables in all schemas' do
      schema_table_hash.each do |schema_name, tables|
        tables.each do |table_name|
          expect(DuplicateRowCheckerJob).to receive(:perform_later).with(table_name, schema_name)
        end
      end

      expect { ExtractorRowCheckerEnqueueJob.new.perform }.not_to raise_error
    end

    it 'logs an error when enqueuing a job fails' do
      allow(DuplicateRowCheckerJob).to receive(:perform_later).
        and_raise(StandardError.new('Job failed'))
      allow(Rails.logger).to receive(:error)

      ExtractorRowCheckerEnqueueJob.new.perform

      schema_table_hash.each do |schema_name, tables|
        tables.each do |table_name|
          expect(Rails.logger).to have_received(:error).
            with("ExtractorRowCheckerEnqueueJob:Failed to enqueue job for table
#{table_name} in schema #{schema_name}: Job failed")
        end
      end
    end
  end
end
