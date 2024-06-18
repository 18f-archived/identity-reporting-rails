class DuplicateRowCheckerJob < ApplicationJob
  queue_as :default

  def perform(table_name:, schema_name:, uniq_by:)
    @table_name = DataWarehouseApplicationRecord.connection.quote_table_name(table_name)
    @schema_name = DataWarehouseApplicationRecord.connection.quote_table_name(schema_name)

    Rails.logger.info "DuplicateRowCheckerJob: Checking for duplicates in " \
    "#{@schema_name}.#{@table_name}"

    query = build_query(uniq_by)

    duplicates = DataWarehouseApplicationRecord.connection.exec_query(query)
    log_result(duplicates)
  end

  private

  def build_query(uniq_by)
    if uniq_by == 'message'
      id_key = extract_json_key(column: 'message', key: 'id')
      <<-SQL
        SELECT #{id_key} AS message_id, COUNT(*)
        FROM #{@schema_name}.#{@table_name}
        GROUP BY message_id
        HAVING COUNT(*) > 1
      SQL
    else
      <<-SQL
        SELECT id, COUNT(*)
        FROM #{@schema_name}.#{@table_name}
        GROUP BY id
        HAVING COUNT(*) > 1
      SQL
    end
  end

  def extract_json_key(column:, key:)
    if Rails.env.production?
      # Redshift environment using SUPER Column type
      "#{column}.#{key}"
    else
      # Local/Test environment using JSONB Column type
      "json_extract_path_text(#{column}, '#{key}')"
    end
  end

  def log_result(duplicates)
    if duplicates.any?
      Rails.logger.warn "DuplicateRowCheckerJob: Found #{duplicates.count} duplicate(s) in " \
                        "#{@schema_name}.#{@table_name}"
    else
      Rails.logger.info "DuplicateRowCheckerJob: No duplicates found in " \
                        "#{@schema_name}.#{@table_name}"
    end
  end
end
