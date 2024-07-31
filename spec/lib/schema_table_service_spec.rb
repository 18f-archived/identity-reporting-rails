require 'rails_helper'
require 'schema_table_service'

RSpec.describe SchemaTableService do
  let!(:schema_table_service) { SchemaTableService.new }

  describe 'get schema table details from DB' do
    context 'when schema and table exists' do
      it 'validate results from DB' do
        schema_table_hash = schema_table_service.generate_schema_table_hash
        expect(schema_table_hash).not_to be_empty
        expect(schema_table_hash.keys).to include('logs')
        expect(schema_table_hash.keys).to include('idp')
        schema_table_hash.each do |schema_name, tables|
          expect(tables).to be_a(Array)
          if schema_name == 'logs'
            expect(tables).to include('events')
            expect(tables).to include('production')
          end
        end
      end
    end
    context 'when schema exists but not tables' do
      let!(:schema_name) { { 'logs' => [], 'idp' => [] } }

      it 'Validate for empty set of tables' do
        schema_table_hash = schema_table_service.fetch_tables_for_schema(schema_name)
        schema_table_hash.each do |schema_name, tables|
          expect(tables).to be_a(Array)
          if schema_name == 'logs'
            expect(tables).to be nil
          end
        end
        # expect(Rails.logger).to receive(:error).with(/Error loading DataWarehouseApplicationRecord dependency:/)
        # expect(schema_table_hash).to be_empty
      end
    end
  end

  describe 'require_dependency_l' do
    context 'when dependency is not loaded' do
      let!(:dependency) { 'data_warehouse_application_record' }
      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with(/Error loading dependency:/)
        schema_table_service.require_dependency_l(dependency)
      end
    end
  end
end
