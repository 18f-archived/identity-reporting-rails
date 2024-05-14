class DuplicateRowCheckerJob < ApplicationJob
  queue_as :default

  def perform(table_name, schema_name, uniq_by)
    @table_name = DataWarehouseApplicationRecord.connection.quote_table_name(table_name)
    @schema_name = DataWarehouseApplicationRecord.connection.quote_table_name(schema_name)

    Rails.logger.info "DuplicateRowCheckerJob: Checking for duplicates in " \
    "#{@schema_name}.#{@table_name}"

    if uniq_by == 'message'
      query = <<-SQL
        SELECT JSON_EXTRACT_PATH_TEXT(message, 'id') AS id, COUNT(*)
        FROM #{@schema_name}.#{@table_name}
        WHERE CAN_JSON_PARSE(message)
        GROUP BY id
        HAVING COUNT(*) > 1
      SQL
    else
      query = <<-SQL
        SELECT #{uniq_by}, COUNT(*)
        FROM #{@schema_name}.#{@table_name}
        GROUP BY #{uniq_by}
        HAVING COUNT(*) > 1
      SQL
    end

    result = DataWarehouseApplicationRecord.connection.execute(query)
    duplicates = result.to_a

    if duplicates.any?
      Rails.logger.info "DuplicateRowCheckerJob: Found #{duplicates.count} duplicates in " \
                        "#{@schema_name}.#{@table_name}"
    else
      Rails.logger.info "DuplicateRowCheckerJob: No duplicates found in " \
                        "#{@schema_name}.#{@table_name}"
    end

    duplicates
  end
end
