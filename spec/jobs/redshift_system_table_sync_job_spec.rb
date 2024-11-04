require 'rails_helper'

RSpec.describe RedshiftSystemTableSyncJob, type: :job do
  let(:job) { RedshiftSystemTableSyncJob.new }
  let(:source_table) { 'stl_query' }
  let(:target_schema) { 'test_pg_catalog' }
  let(:target_table_with_schema) { "#{target_schema}.#{source_table}" }
  let(:timestamp_column) { 'endtime' }
  let(:primary_key) { 'userid' }
  let(:last_sync_time) { Time.zone.now - 6.days }
  let!(:file_path) { Rails.root.join('spec', 'fixtures', 'redshift_system_tables.yml') }
  let(:table) do
    {
      'name' => source_table,
      'primary_key' => primary_key,
      'timestamp_column' => timestamp_column,
      'target_table' => source_table,
      'target_schema' => target_schema,
    }
  end

  before do
    job.send(:setup_instance_variables, table)
    allow(job).to receive(:config_file_path).and_return(file_path)
  end

  describe '#perform' do
    it 'upserts data into the target table' do
      allow(Rails.logger).to receive(:info).and_call_original
      msg = {
        job: 'RedshiftSystemTableSyncJob',
        success: true,
        message: 'Upserted data into test_pg_catalog.stl_query',
      }

      # TODO: Update this merge statement code and test
      # expect(Rails.logger).to receive(:info).with(msg.to_json)
      # job.perform
    end
  end

  describe '#table_definitions' do
    it 'return table definitions from the config file' do
      table_definitions = job.send(:table_definitions)
      expect(table_definitions).to match_array(
        [{ 'name' => 'stl_query',
           'primary_key' => 'userid',
           'timestamp_column' => 'endtime',
           'target_table' => 'stl_query',
           'target_schema' => 'test_pg_catalog' }],
      )
    end
  end

  describe '#target_table_exists?' do
    it 'returns true if the target table exists' do
      expect(DataWarehouseApplicationRecord.connection.table_exists?(target_table_with_schema)).to be true
    end

    it 'returns false if the target table exists' do
      expect(SystemMetadataApplicationRecord.connection.table_exists?(target_table_with_schema)).to be false
    end
  end

  describe '#create_target_table' do
    it 'creates target tables, and log message' do
      expect(DataWarehouseApplicationRecord.connection.table_exists?(target_table_with_schema)).to be true
      expect(SystemMetadataApplicationRecord.connection.table_exists?(target_table_with_schema)).to be false

      allow(Rails.logger).to receive(:info).and_call_original
      msg = {
        job: 'RedshiftSystemTableSyncJob',
        success: true,
        message: 'Created target table test_pg_catalog.stl_query',
        target_table: 'test_pg_catalog.stl_query',
      }
      expect(Rails.logger).to receive(:info).with(msg.to_json)

      job.send(:create_target_table)

      expect(SystemMetadataApplicationRecord.connection.table_exists?(target_table_with_schema)).to be true
    end
  end

  describe '#create_schema_if_not_exists' do
    it 'creates target schema, and log message' do
      allow(Rails.logger).to receive(:info).and_call_original
      msg = {
        job: 'RedshiftSystemTableSyncJob',
        success: true,
        message: 'Schema test_pg_catalog created',
      }
      expect(Rails.logger).to receive(:info).with(msg.to_json)

      job.send(:create_schema_if_not_exists)
    end

    context 'when schema already exists' do
      let(:target_schema) { 'pg_catalog' }

      it 'return target schema if already exists, and log message' do
        allow(Rails.logger).to receive(:info).and_call_original
        msg = {
          job: 'RedshiftSystemTableSyncJob',
          success: true,
          message: 'Schema pg_catalog already created',
        }
        expect(Rails.logger).to receive(:info).with(msg.to_json)

        job.send(:create_schema_if_not_exists)
      end
    end
  end

  describe '#fetch_source_columns' do
    it 'returns column information' do
      columns = job.send(:fetch_source_columns)

      expect(columns).to match_array(
        [
          { 'column' => 'userid', 'type' => 'integer' },
          { 'column' => 'query', 'type' => 'integer' },
          { 'column' => 'label', 'type' => 'character varying' },
          { 'column' => 'xid', 'type' => 'bigint' },
          { 'column' => 'pid', 'type' => 'integer' },
          { 'column' => 'database', 'type' => 'character varying' },
          { 'column' => 'querytxt', 'type' => 'character varying' },
          { 'column' => 'starttime', 'type' => 'timestamp without time zone' },
          { 'column' => 'endtime', 'type' => 'timestamp without time zone' },
          { 'column' => 'aborted', 'type' => 'integer' },
          { 'column' => 'insert_pristine', 'type' => 'integer' },
          { 'column' => 'concurency_scalling_status', 'type' => 'integer' },
        ],
      )
    end
  end

  describe '#update_sync_time' do
    it 'updates the sync time in SystemTableSyncMetadata' do
      job.send(:update_sync_time)

      sync_metadata = SystemTableSyncMetadata.find_by(table_name: target_table_with_schema)
      expect(sync_metadata).not_to be_nil
      expect(sync_metadata.last_sync_time).to be_within(1.second).of(Time.zone.now)
      expect(sync_metadata.table_name).to eq target_table_with_schema
    end
  end
end
