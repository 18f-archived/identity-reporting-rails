require 'rails_helper'
require 'schema_table_service'

RSpec.describe SchemaTableService do
  let!(:schema_table_service) { SchemaTableService.new }

  describe 'get schema details from DB' do
    context 'validating the class' do
      it 'pull schema details' do
        schema_table_hash = schema_table_service.generate_schema_table_hash
        expect(schema_table_hash).to be_a(Hash)
        puts("schema_table_hash: #{schema_table_hash}\n")
      end
    end
    context 'Validate the table exists' do
      it 'pull table details' do
        table_name = 'logs.events'
        table_exists = schema_table_service.table_exists?(table_name)
        expect(table_exists).to eq(true)
        puts("Table exists: #{table_exists}")
      end
    end
  end
end
