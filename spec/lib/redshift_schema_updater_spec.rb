require 'rails_helper'
require 'redshift_schema_updater'

RSpec.describe RedshiftSchemaUpdater do
  let!(:file_path) { Rails.root.join('spec', 'fixtures', 'includes_columns.yml') }
  let!(:users_table) { 'users' }
  let!(:events_table) { 'events' }
  let!(:expected_columns) { ['id', 'name', 'email', 'created_at', 'updated_at'] }
  let!(:yaml_data) do
    [
      {
        'table' => 'users',
        'schema' => 'public',
        'include_columns' => {
          'id' => { 'datatype' => 'integer' },
          'name' => { 'datatype' => 'string' },
          'email' => { 'datatype' => 'string' },
          'created_at' => { 'datatype' => 'datetime' },
          'updated_at' => { 'datatype' => 'datetime' },
        },
      },
      {
        'table' => 'events',
        'schema' => 'public',
        'include_columns' => {
          'id' => { 'datatype' => 'integer' },
          'name' => { 'datatype' => 'string' },
          'event_type' => { 'datatype' => 'integer' },
          'created_at' => { 'datatype' => 'datetime' },
          'updated_at' => { 'datatype' => 'datetime' },
        },
      },
    ]
  end

  describe '.update_schema_from_yaml' do
    context 'when table does not exist' do
      it 'creates new table' do
        expect(RedshiftSchemaUpdater.send(:table_exists?, users_table)).to eq(false)
        expect(RedshiftSchemaUpdater.send(:table_exists?, events_table)).to eq(false)

        RedshiftSchemaUpdater.update_schema_from_yaml(file_path)

        expect(RedshiftSchemaUpdater.send(:table_exists?, users_table)).to eq(true)
        expect(RedshiftSchemaUpdater.send(:table_exists?, events_table)).to eq(true)
      end
    end

    context 'when table already exists' do
      let(:existing_columns) { { 'id' => { 'datatype' => 'integer' } } }

      before do
        RedshiftSchemaUpdater.send(:create_table, users_table, existing_columns)
      end

      it 'adds new columns' do
        expect(RedshiftSchemaUpdater.send(:table_exists?, users_table)).to eq(true)
        expect(ActiveRecord::Base.connection.columns(users_table).map(&:name)).to eq(['id'])

        RedshiftSchemaUpdater.update_schema_from_yaml(file_path)

        new_columns = ActiveRecord::Base.connection.columns(users_table).map(&:name)
        expect(new_columns).to eq(expected_columns)
      end
    end

    context 'when table already exists with extra columns' do
      let(:existing_columns) do
        { 'id' => { 'datatype' => 'integer' }, 'phone' => { 'datatype' => 'string' } }
      end

      before do
        RedshiftSchemaUpdater.send(:create_table, users_table, existing_columns)
      end

      it 'updates columns and removes columns not exist in YAML file' do
        expect(RedshiftSchemaUpdater.send(:table_exists?, users_table)).to eq(true)
        existing_columns = ActiveRecord::Base.connection.columns(users_table).map(&:name)
        expect(existing_columns).to eq(['id', 'phone'])

        RedshiftSchemaUpdater.update_schema_from_yaml(file_path)

        new_columns = ActiveRecord::Base.connection.columns(users_table).map(&:name)
        expect(new_columns).to eq(expected_columns)
      end
    end
  end

  describe '.establish_data_warehouse_connection' do
    it 'establishes connection to the data warehouse' do
      expect(ActiveRecord::Base).to receive(:establish_connection).
        with(:data_warehouse).and_call_original

      RedshiftSchemaUpdater.send(:establish_data_warehouse_connection)
    end
  end

  describe '.load_yaml' do
    context 'when YAML file exists' do
      it 'loads YAML file' do
        expect(RedshiftSchemaUpdater.send(:load_yaml, file_path)).to eq(yaml_data)
      end
    end

    context 'when YAML file does not exist' do
      let!(:file_path) { 'path/to/nonexistent/file.yml' }
      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with(/Error loading include columns YML file:/)
        RedshiftSchemaUpdater.send(:load_yaml, file_path)
      end

      it 'returns nil' do
        expect(RedshiftSchemaUpdater.send(:load_yaml, file_path)).to be_nil
      end
    end
  end

  describe 'redshift_data_type_mappings' do
    context 'when datatype is :json or :jsonb' do
      it 'returns :super' do
        expect(RedshiftSchemaUpdater.send(:redshift_data_type_mappings, 'json')).to eq(:super)
        expect(RedshiftSchemaUpdater.send(:redshift_data_type_mappings, 'jsonb')).to eq(:super)
      end
    end

    context 'when datatype is not :json or :jsonb' do
      it 'returns the input datatype symbol' do
        expect(RedshiftSchemaUpdater.send(:redshift_data_type_mappings, 'integer')).to eq(:integer)
        expect(RedshiftSchemaUpdater.send(:redshift_data_type_mappings, 'string')).to eq(:string)
      end
    end
  end
end
