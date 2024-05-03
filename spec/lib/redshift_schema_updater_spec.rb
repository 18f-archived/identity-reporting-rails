require 'rails_helper'
require 'redshift_schema_updater'

RSpec.describe RedshiftSchemaUpdater do
  let!(:file_path) { 'include_columns.yml' }
  let!(:yaml_data) do
    [
      {
        'table' => 'table1',
        'include_columns' => { 'column1' => { 'datatype' => 'string' } },
      },
      {
        'table' => 'table2',
        'include_columns' => { 'column2' => { 'datatype' => 'integer' } },
      },
    ]
  end

  describe '.update_schema_from_yaml' do
    context 'when YAML file exists' do
      before do
        allow(YAML).to receive(:load_file).with(file_path).and_return(yaml_data)
        allow(Rails.logger).to receive(:error)
      end

      it 'establishes connection to the data warehouse' do
        expect(ActiveRecord::Base).to receive(:establish_connection).with(:data_warehouse)
        RedshiftSchemaUpdater.update_schema_from_yaml(file_path)
      end

      it 'loads YAML file' do
        expect(YAML).to receive(:load_file).with(file_path).and_return(yaml_data)
        RedshiftSchemaUpdater.update_schema_from_yaml(file_path)
      end

      it 'updates existing tables or creates new tables based on YAML data' do
        allow(RedshiftSchemaUpdater).to receive(:table_exists?).with('table1').and_return(true)
        allow(RedshiftSchemaUpdater).to receive(:table_exists?).with('table2').and_return(false)

        expect(RedshiftSchemaUpdater).to receive(:update_existing_table).with(
          'table1',
          { 'column1' => { 'datatype' => 'string' } },
        )
        expect(RedshiftSchemaUpdater).to receive(:create_table).with(
          'table2',
          { 'column2' => { 'datatype' => 'integer' } },
        )

        RedshiftSchemaUpdater.update_schema_from_yaml(file_path)
      end
    end

    context 'when YAML file does not exist' do
      let(:file_path) { 'path/to/nonexistent/file.yml' }

      before do
        allow(YAML).to receive(:load_file).with(file_path).and_raise(Errno::ENOENT)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with(/Error loading include columns YML file:/)
        RedshiftSchemaUpdater.update_schema_from_yaml(file_path)
      end
    end
  end

  describe '.establish_data_warehouse_connection' do
    it 'establishes connection to the data warehouse' do
      expect(ActiveRecord::Base).to receive(:establish_connection).with(:data_warehouse)
      RedshiftSchemaUpdater.send(:establish_data_warehouse_connection)
    end
  end

  describe '.load_yaml' do
    context 'when YAML file exists' do
      before do
        allow(YAML).to receive(:load_file).with(file_path).and_return(yaml_data)
      end

      it 'loads YAML file' do
        expect(RedshiftSchemaUpdater.send(:load_yaml, file_path)).to eq(yaml_data)
      end
    end

    context 'when YAML file does not exist' do
      before do
        allow(YAML).to receive(:load_file).with(file_path).and_raise(Errno::ENOENT)
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

  describe '.table_exists?' do
    it 'checks if table exists in the database' do
      allow(ActiveRecord::Base.connection).to receive(:table_exists?).
        with('example_table').and_return(true)
      expect(RedshiftSchemaUpdater.send(:table_exists?, 'example_table')).to eq(true)
    end
  end

  describe '.update_existing_table' do
    let(:existing_columns) { [double(name: 'existing_column')] }
    let(:columns) { { 'new_column' => { 'datatype' => 'string' } } }

    before do
      allow(ActiveRecord::Base.connection).to receive(:columns).and_return(existing_columns)
    end

    it 'adds new columns and removes columns not in the YAML file' do
      expect(RedshiftSchemaUpdater).to receive(:add_column).with(
        'test_table',
        'new_column',
        'string',
      )
      expect(RedshiftSchemaUpdater).to receive(:remove_column).with('test_table', 'existing_column')
      RedshiftSchemaUpdater.send(:update_existing_table, 'test_table', columns)
    end
  end

  describe '.create_table' do
    let(:columns) { { 'new_column' => { 'datatype' => 'string' } } }

    it 'creates a new table with the specified columns' do
      expect(ActiveRecord::Base.connection).to receive(:create_table).with(:test_table)
      RedshiftSchemaUpdater.send(:create_table, 'test_table', columns)
    end
  end

  describe '.add_column' do
    it 'adds a new column to an existing table' do
      expect(ActiveRecord::Base.connection).to receive(:add_column).with(
        :test_table, :new_column,
        :string
      )
      RedshiftSchemaUpdater.send(:add_column, 'test_table', 'new_column', 'string')
    end
  end

  describe '.remove_column' do
    it 'removes a column from an existing table' do
      expect(ActiveRecord::Base.connection).to receive(:remove_column).with(
        :test_table,
        :column_to_remove,
      )
      RedshiftSchemaUpdater.send(:remove_column, 'test_table', 'column_to_remove')
    end
  end
end
