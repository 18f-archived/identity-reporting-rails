class RedshiftUnloadLogCheckerJob < ApplicationJob
  queue_as :default

  def perform
    fetch_data_from_redshift
  end

  private

  def fetch_data_from_redshift
    build_params = {
      transfer_size_threshold: Identity::Hostdata.config.transfer_size_threshold_in_bytes,
    }

    query = format(<<~SQL, build_params)
      SELECT userid, start_time, end_time, path as s3_path, query as query_id
      FROM stl_unload_log
      WHERE transfer_size > %{transfer_size_threshold}
    SQL

    result = DataWarehouseApplicationRecord.connection.exec_query(query).to_a
    if result.present?
      merge_result = result.map do |row|
        {
          userid: row['userid'],
          starttime: row['start_time'],
          endtime: row['end_time'],
          s3_path: row['s3_path'],
          query_id: row['query_id'],
        }
      end
      log_info(
        'RedshiftUnloadLogCheckerJob: Found unload logs above threshold', false,
        data: merge_result
      )
    else
      log_info('RedshiftUnloadLogCheckerJob: No unload logs found above threshold', true)
    end
  end

  def log_info(message, success, additional_info = {})
    Rails.logger.info(
      {
        job: self.class.name,
        success: success,
        message: message,
      }.merge(additional_info).to_json,
    )
  end
end
