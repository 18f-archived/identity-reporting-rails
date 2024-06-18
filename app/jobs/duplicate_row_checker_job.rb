class DuplicateRowCheckerJob < ApplicationJob
  queue_as :default

  def perform(table_name:, schema_name:, uniq_by:)
    @table_name = DataWarehouseApplicationRecord.connection.quote_table_name(table_name)
    @schema_name = DataWarehouseApplicationRecord.connection.quote_table_name(schema_name)

    Rails.logger.info "DuplicateRowCheckerJob: Checking for duplicates in " \
    "#{@schema_name}.#{@table_name}"

    if uniq_by == 'message'
      id_key = extract_json_key(column: 'message', key: 'id')
      query = <<-SQL
        SELECT #{id_key} AS message_id, COUNT(*)
        FROM #{@schema_name}.#{@table_name}
        GROUP BY message_id
        HAVING COUNT(*) > 1
      SQL
    else
      query = <<-SQL
        SELECT id, COUNT(*)
        FROM #{@schema_name}.#{@table_name}
        GROUP BY id
        HAVING COUNT(*) > 1
      SQL
    end

    duplicates = DataWarehouseApplicationRecord.connection.execute(query)
    if duplicates.any?
      Rails.logger.warn "DuplicateRowCheckerJob: Found #{duplicates.count} duplicate(s) in " \
                        "#{@schema_name}.#{@table_name}"
    else
      Rails.logger.info "DuplicateRowCheckerJob: No duplicates found in " \
                        "#{@schema_name}.#{@table_name}"
    end
  end

  private

  def extract_json_key(column:, key:)
    if Rails.env.production?
      # Redshift environment using SUPER Column type
      "#{column}.#{key}"
    else
      # Local/Test environment using JSONB Column type
      "JSON_EXTRACT_PATH_TEXT(#{column}, '#{key}')"
    end
  end
end
