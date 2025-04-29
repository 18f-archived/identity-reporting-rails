require 'rails_helper'
require 'redshift_schema_updater'

RSpec.describe RedshiftSchemaUpdater do
  let!(:redshift_schema_updater) { RedshiftSchemaUpdater.new('idp') }
  let!(:file_path) { Rails.root.join('spec', 'fixtures', 'includes_columns.yml') }
  let!(:file_path2) { Rails.root.join('spec', 'fixtures', 'includes_columns2.yml') }
  let!(:users_table) { 'idp.new_users' }
  let!(:events_table) { 'idp.events' }
  let!(:primary_key) { 'id' }
  let!(:expected_columns) { ['id', 'name', 'email', 'created_at', 'updated_at'] }
  let!(:yaml_data) do
    [
      {
        'table' => 'new_users',
        'schema' => 'public',
        'primary_key' => 'id',
        'include_columns' => [
          { 'name' => 'id', 'datatype' => 'integer', 'not_null' => true },
          { 'name' => 'name', 'datatype' => 'string', 'not_null' => true },
          { 'name' => 'email', 'datatype' => 'string' },
          { 'name' => 'created_at', 'datatype' => 'datetime' },
          { 'name' => 'updated_at', 'datatype' => 'datetime' },
        ],
      },
      {
        'table' => 'events',
        'schema' => 'public',
        'primary_key' => 'id',
        'foreign_keys' => [
          {
            'column' => 'new_user_id',
            'references' => {
              'table' => 'new_users',
              'column' => 'id',
            },
          },
          {
            'column' => 'name',
            'references' => {
              'table' => 'new_users',
              'column' => 'name',
            },
          },
        ],
        'include_columns' => [
          { 'name' => 'id', 'datatype' => 'integer', 'not_null' => true },
          { 'name' => 'name', 'datatype' => 'string' },
          { 'name' => 'new_user_id', 'datatype' => 'integer' },
          { 'name' => 'event_type', 'datatype' => 'integer' },
          { 'name' => 'created_at', 'datatype' => 'datetime' },
          { 'name' => 'updated_at', 'datatype' => 'datetime' },
        ],
      },
    ]
  end

  describe '.update_schema_from_yaml' do
    context 'when table does not exist' do
      it 'creates new table' do
        expect(redshift_schema_updater.table_exists?(users_table)).to eq(false)
        expect(redshift_schema_updater.table_exists?(events_table)).to eq(false)

        redshift_schema_updater.update_schema_from_yaml(file_path)

        expect(redshift_schema_updater.table_exists?(users_table)).to eq(true)
        expect(redshift_schema_updater.table_exists?(events_table)).to eq(true)

        # validate primary and foreign keys column are set as NOT NULL
        users_columns = DataWarehouseApplicationRecord.connection.columns(users_table)
        expect(users_columns.map(&:name)).to include('id')
        # validate id is set as NOT NULL
        id_column = users_columns.find { |col| col.name == 'id' }
        expect(id_column.null).to eq(false)

        primary_key_query = <<~SQL
          SELECT kcu.column_name
          FROM information_schema.table_constraints tco
          JOIN information_schema.key_column_usage kcu
          ON kcu.constraint_name = tco.constraint_name
          WHERE tco.table_name = 'new_users' AND tco.constraint_type = 'PRIMARY KEY';
        SQL
        primary_key_result = DataWarehouseApplicationRecord.
          connection.exec_query(primary_key_query).to_a
        expect(primary_key_result.map { |row| row['column_name'] }).to include('id')
        foreign_key_query = <<~SQL
          SELECT kcu.column_name, ccu.table_name, ccu.column_name as referenced_column_name
          FROM information_schema.table_constraints tco
          JOIN information_schema.key_column_usage kcu
          ON kcu.constraint_name = tco.constraint_name
          JOIN information_schema.constraint_column_usage ccu
          ON ccu.constraint_name = tco.constraint_name
          WHERE tco.table_name = 'events' AND tco.constraint_type = 'FOREIGN KEY';
        SQL
        foreign_key_result = DataWarehouseApplicationRecord.
          connection.exec_query(foreign_key_query).to_a
        expect(foreign_key_result.map { |row| row['column_name'] }).to include('new_user_id')
        expect(foreign_key_result.map { |row| row['table_name'] }).to include('new_users')
        expect(foreign_key_result.map { |row| row['referenced_column_name'] }).to include('id')
        expect(foreign_key_result.map { |row| row['column_name'] }).to include('name')
        expect(foreign_key_result.map { |row| row['table_name'] }).to include('new_users')
        expect(foreign_key_result.map { |row| row['referenced_column_name'] }).to include('name')
      end
    end

    context 'when table already exists' do
      let(:existing_columns) { [{ 'name' => 'id', 'datatype' => 'integer' }] }
      let(:foreign_keys) { [] }

      before do
        redshift_schema_updater.
          create_table(users_table, existing_columns, primary_key, foreign_keys)
      end

      it 'adds new columns' do
        expect(redshift_schema_updater.table_exists?(users_table)).to eq(true)
        existing_columns = DataWarehouseApplicationRecord.connection.columns(users_table)
        expect(existing_columns.map(&:name)).to eq(['id'])

        redshift_schema_updater.update_schema_from_yaml(file_path)

        new_columns = DataWarehouseApplicationRecord.connection.columns(users_table).map(&:name)
        expect(new_columns).to eq(expected_columns)
      end
    end

    context 'when table already exists with extra columns' do
      let(:existing_columns) do
        [{ 'name' => 'id', 'datatype' => 'integer' }, { 'name' => 'phone', 'datatype' => 'string' }]
      end
      let(:foreign_keys) { [] }
      let(:primary_key) { nil }

      before do
        redshift_schema_updater.
          create_table(users_table, existing_columns, primary_key, foreign_keys)
      end

      it 'updates columns and removes columns not exist in YAML file' do
        expect(redshift_schema_updater.table_exists?(users_table)).to eq(true)
        existing_columns = DataWarehouseApplicationRecord.connection.columns(users_table)
        expect(existing_columns.map(&:name)).to eq(['id', 'phone'])

        redshift_schema_updater.update_schema_from_yaml(file_path)

        new_columns = DataWarehouseApplicationRecord.connection.columns(users_table).map(&:name)
        expect(new_columns).to eq(expected_columns)
      end
    end

    context 'when an existing column changes data type,' do
      let(:existing_columns) do
        [{ 'name' => 'id', 'datatype' => 'integer' },
         { 'name' => 'some_numeric_column', 'datatype' => 'decimal' }]
      end
      let(:foreign_keys) { [] }

      before do
        DataWarehouseApplicationRecord.establish_connection(:data_warehouse)
        redshift_schema_updater.
          create_table(users_table, existing_columns, primary_key, foreign_keys)
        DataWarehouseApplicationRecord.connection.execute(
          DataWarehouseApplicationRecord.sanitize_sql(
            "INSERT INTO #{users_table} (id, some_numeric_column) VALUES (1, 999.0)",
          ), allow_retry: true
        )
      end

      it 'updates columns, drops columns with old data type, replaces with new data type' do
        expect(redshift_schema_updater.table_exists?(users_table)).to eq(true)
        column_obs = DataWarehouseApplicationRecord.connection.columns(users_table)
        type = column_obs.find { |col| col.name == 'some_numeric_column' }.type
        expect(type).to eq(:decimal)

        redshift_schema_updater.update_schema_from_yaml(file_path2)

        column_obs = DataWarehouseApplicationRecord.connection.columns(users_table)
        type = column_obs.find { |col| col.name == 'some_numeric_column' }.type
        expect(type).to eq(:integer)

        results = DataWarehouseApplicationRecord.connection.execute(
          DataWarehouseApplicationRecord.sanitize_sql(
            "SELECT id, some_numeric_column FROM #{users_table};",
          ),
        )
        expect(results.values).to eq([[1, 999]])
      end
    end

    context 'when a string column has their limit value updated in yaml file,' do
      let(:existing_columns) do
        [{ 'name' => 'id', 'datatype' => 'integer' },
         { 'name' => 'string_with_limit', 'datatype' => 'string', 'limit' => 100 }]
      end
      let(:foreign_keys) { [] }

      before do
        DataWarehouseApplicationRecord.establish_connection(:data_warehouse)
        redshift_schema_updater.
          create_table(users_table, existing_columns, primary_key, foreign_keys)
      end

      it 'updates column with new limit' do
        columns_objs = DataWarehouseApplicationRecord.connection.columns(users_table)
        string_col = columns_objs.find { |col| col.name == 'string_with_limit' }
        expect(string_col.limit).to eq(100)

        redshift_schema_updater.update_schema_from_yaml(file_path2)

        columns_objs = DataWarehouseApplicationRecord.connection.columns(users_table)
        string_col = columns_objs.find { |col| col.name == 'string_with_limit' }
        expect(string_col.limit).to eq(300)
      end
    end

    context 'when a string column has a limit value added in yaml file for the first time,' do
      let(:existing_columns) do
        [{ 'name' => 'id', 'datatype' => 'integer' },
         { 'name' => 'string_with_limit', 'datatype' => 'string' }]
      end
      let(:foreign_keys) { [] }
      before do
        DataWarehouseApplicationRecord.establish_connection(:data_warehouse)
        redshift_schema_updater.
          create_table(users_table, existing_columns, primary_key, foreign_keys)
      end

      it 'updates column with new limit' do
        columns_objs = DataWarehouseApplicationRecord.connection.columns(users_table)
        string_col = columns_objs.find { |col| col.name == 'string_with_limit' }
        expect(string_col.limit).to eq(nil)

        redshift_schema_updater.update_schema_from_yaml(file_path2)

        columns_objs = DataWarehouseApplicationRecord.connection.columns(users_table)
        string_col = columns_objs.find { |col| col.name == 'string_with_limit' }
        expect(string_col.limit).to eq(300)
      end
    end

    context 'when table already exist skip primary and foreign key' do
      let(:existing_columns) do
        [{ 'name' => 'id', 'datatype' => 'integer', 'not_null' => true }]
      end
      let(:foreign_keys) { [] }
      before do
        allow(redshift_schema_updater).to receive(:log_info)
        allow(redshift_schema_updater).to receive(:log_error)
        allow(redshift_schema_updater).to receive(:log_warning)
        DataWarehouseApplicationRecord.establish_connection(:data_warehouse)
        redshift_schema_updater.
          create_table(users_table, existing_columns, primary_key, foreign_keys)
      end

      it 'updates columns and skips primary and foreign key' do
        expect(redshift_schema_updater.table_exists?(users_table)).to eq(true)
        existing_columns = DataWarehouseApplicationRecord.connection.columns(users_table)
        expect(existing_columns.map(&:name)).to eq(['id'])

        redshift_schema_updater.update_schema_from_yaml(file_path)

        new_columns = DataWarehouseApplicationRecord.connection.columns(users_table).map(&:name)

        expect(new_columns).to eq(expected_columns)
        # validate primary and foreign keys validation is skipped logs
        allow(Rails.logger).to receive(:info).and_call_original

        msg = 'Foreign keys and Primary_keys are not processed'
        expect(redshift_schema_updater).to have_received(:log_info).with(msg)
      end
    end
  end

  describe '.load_yaml' do
    context 'when YAML file exists' do
      it 'loads YAML file' do
        expect(redshift_schema_updater.send(:load_yaml, file_path)).to eq(yaml_data)
      end
    end

    context 'when YAML file does not exist' do
      let!(:file_path) { 'path/to/nonexistent/file.yml' }
      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with(/Error loading include columns YML file:/)
        redshift_schema_updater.send(:load_yaml, file_path)
      end

      it 'returns nil' do
        expect(redshift_schema_updater.send(:load_yaml, file_path)).to be_nil
      end
    end
  end

  describe 'redshift_data_type' do
    context 'when datatype is :json or :jsonb' do
      it 'returns :super' do
        expect(redshift_schema_updater.redshift_data_type('json')).to eq('super')
        expect(redshift_schema_updater.redshift_data_type('jsonb')).to eq('super')
      end
    end

    context 'when datatype is not :json or :jsonb' do
      it 'returns the input datatype symbol' do
        expect(redshift_schema_updater.redshift_data_type('integer')).to eq('integer')
        expect(redshift_schema_updater.redshift_data_type('string')).to eq('string')
      end
    end
  end
end
