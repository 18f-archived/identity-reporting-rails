class PiiRowCheckerJob < ApplicationJob
  queue_as :default

  def perform(table_name)
    @schema_name = 'logs'
    @table_name = table_name
    # Ensure that the target table name is valid and it starts with unextracted_
    unless @table_name.start_with?('unextracted_')
      raise "Invalid target table name: #{@table_name}"
    end

    list_pattern_hash = {
      phone_number: '314-555-1212',
      dob_with_slash: '10/0/1938',
      dob_with_dash: '1938-10-06',
      address_without_zipcode1: '1 Microsoft Way',
      address_without_zipcode2: 'BaySide',
      name1: 'Fakey',
      name2: 'McFakerson',
    }

    combined_pattern = list_pattern_hash.values.join('|')
    source_table_count =
      DataWarehouseApplicationRecord.connection.exec_query(source_table_count_query).first['count']

    if source_table_count > 0
      pattern_query = build_pattern_query(combined_pattern)
      Rails.logger.info 'PiiRowCheckerJob: Executing query for combined patterns...'
      pattern_result = DataWarehouseApplicationRecord.connection.exec_query(pattern_query)
      log_pattern_results(list_pattern_hash, pattern_result)
    else
      Rails.logger.info "PiiRowCheckerJob: no data in table #{@schema_name}.#{@table_name}"
      return
    end
    Rails.logger.info 'PiiRowCheckerJob: Query executed successfully'
  end

  private

  def build_pattern_query(pattern)
    <<-SQL
      SELECT *
      FROM #{@schema_name}.#{@table_name}
      WHERE CAST(message AS VARCHAR) ~* '#{pattern}'
    SQL
  end

  def source_table_count_query
    <<-SQL
        SELECT COUNT(*) as count
        FROM #{@schema_name}.#{@table_name}
    SQL
  end

  def log_pattern_results(list_hash, results)
    if results.any?
      results.each do |row|
        list_hash.each do |name, pattern|
          if row['message'].match?(/#{Regexp.escape(pattern)}/i)
            Rails.logger.warn(
              "PiiRowCheckerJob: Found #{name} PII in #{@schema_name}.#{@table_name}",
            )
          end
        end
      end
    else
      Rails.logger.info(
        "PiiRowCheckerJob: No PII found in #{@schema_name}.#{@table_name}",
      )
    end
  end
end
