class DuplicateRowCheckerJob
  def perform(table_name, schema_name)
    @table_name = table_name
    @schema_name = schema_name

    Rails.logger.info "DuplicateRowCheckerJob: Checking for duplicates in " \
                      "#{@schema_name}.#{@table_name}"

    if @schema_name == 'logs'
      result = ActiveRecord::Base.connection.execute(
        "
        SELECT message, COUNT(*)
        FROM #{@schema_name}.#{@table_name}
        WHERE CAN_JSON_PARSE(message)
        GROUP BY 1
        HAVING COUNT(*) > 1
      ",
      )
    else
      result = ActiveRecord::Base.connection.execute(
        "
        SELECT id, COUNT(*)
        FROM #{@schema_name}.#{@table_name}
        GROUP BY id
        HAVING COUNT(*) > 1
      ",
      )
    end

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
