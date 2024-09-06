class PiiRowCheckerJob < ApplicationJob
  queue_as :default

  def perform(table_name)
    @schema_name = 'logs'
    @table_name = table_name
    # Ensure that the target table name is valid and it starts with unextracted_
    unless @table_name.start_with?('unextracted_')
      raise "Invalid target table name: #{@table_name}"
    end

    list_pattern_array = {
      'phone_number' => '(\d{3}-\d{3}-\d{4})',
      'dob_with_slash' => '(\d{2}/\d{2}/\d{4})',
      'dob_with_dash' => '(\d{2}-\d{2}-\d{4})',
      'address_without_zipcode' =>
      '\d+\s+[a-zA-Z0-9\s,.]+,\s*[a-zA-Z\s]+(?!.*\b\d{5}(?:-\d{4})?\b)',
      'fullname_with_upper_Case' => '([A-Z]+ [A-Z]+)',
    }

    if check_table_data > 0
      list_pattern_array.each do |name, pattern|
        pattern_query = build_pattern_query(pattern)
        Rails.logger.info "PiiRowCheckerJob: Executing queries#{@table_name} for pattern #{name}..."
        results = DataWarehouseApplicationRecord.connection.exec_query(pattern_query)
        log_pattern_results(name, results)
      end
    else
      Rails.logger.info "PiiRowCheckerJob: no data in table #{@schema_name}.#{@table_name}"
      return
    end
  end

  private

  def build_pattern_query(pattern)
    <<-SQL
      SELECT *
      FROM #{@schema_name}.#{@table_name}
      WHERE EXISTS (
        SELECT 1
        FROM jsonb_each_text(message) As t
        WHERE t.value ~ '#{pattern}'
      )
    SQL
  end

  def check_table_data
    query = "SELECT COUNT(*) FROM #{@schema_name}.#{@table_name}"
    result = DataWarehouseApplicationRecord.connection.exec_query(query)
    result.rows[0][0].to_i
  end

  def log_pattern_results(pattern_name, results)
    if results.any?
      Rails.logger.warn "PiiRowCheckerJob: Found #{pattern_name} PII in " \
                        "#{@schema_name}.#{@table_name}"
    else
      Rails.logger.info "PiiRowCheckerJob: No PII found in " \
                        "#{@schema_name}.#{@table_name}"
    end
  end
end
