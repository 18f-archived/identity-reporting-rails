class PiiRowCheckerJob < ApplicationJob
  queue_as :default

  def perform(table_name)
    @schema_name = 'logs'
    @table_name = table_name
    # Ensure that the target table name is valid and it starts with unextracted_
    unless @table_name.start_with?('unextracted_')
      raise "Invalid target table name: #{@table_name}"
    end

    Rails.logger.info "P: Checking for PII in " \
    "#{@schema_name}.#{@table_name}"

    # binding.pry
    list_pattern_array = {
      'phone_number' => '(\d{3}-\d{3}-\d{4})',
      'dob_with_slash' => '(\d{2}/\d{2}/\d{4})',
      'dob_with_dash' => '(\d{2}-\d{2}-\d{4})',
      'address_without_zipcode' => '\d+\s+[a-zA-Z0-9\s,.]+,\s*[a-zA-Z\s]+(?!.*\b\d{5}\b)',
      # 'address_without_zipcode' => '\\s*([a-zA-Z0-9_\\s]+),\\s*([a-zA-Z0-9_\\s]+),\\s*([a-zA-Z0-9_\\s]+),\\s*(?!.*\\b\\d{5}\\b)',
      'fullname_with_upper_Case' => '([A-Z]+ [A-Z]+)',
    }

    list_pattern_array.each do |name, pattern|
      pattern_query = build_pattern_query(pattern)
      puts("pattern_query: #{pattern_query}")
      # binding.pry
      Rails.logger.info 'PiiRowCheckerJob: Executing queries {name}...'
      results = DataWarehouseApplicationRecord.connection.exec_query(pattern_query)
      puts("results: #{results.inspect}")
      log_pattern_results(name, results)
    end
    Rails.logger.info 'PiiRowCheckerJob: Query executed successfully'
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

  # def log_pattern_results(pattern_name, results)
  #   Rails.logger.info "P: Found #{pattern_name} in message column: #{results.to_a}"
  # end

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
