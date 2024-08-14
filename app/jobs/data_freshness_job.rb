# DataFreshnessJob
#
# Checks the freshness of the most recent logs.production table against a predefined threshold.
# Logs whether the data is 'within_range' or 'out_of_range' based on how many hours have
# passed since the latest entry. If no logs are found, logs an error message.
#
# Key Components:
# - `DATA_FRESHNESS_THRESHOLD`: Threshold in hours for data freshness.
# - `latest_production_record`: Most recent entry.
# - `freshness_hours`: Time elapsed since the latest record in hours.
# - `status`: Freshness status relative to the threshold.

class DataFreshnessJob < ApplicationJob
  queue_as :default
  DATA_FRESHNESS_THRESHOLD = Identity::Hostdata.config.data_freshness_threshold

  def perform
    latest_production_record = Production.order(timestamp: :desc).first

    if latest_production_record
      freshness_hours = ((Time.zone.now - latest_production_record.timestamp) / 1.hour).round(2)

      status = if freshness_hours <= DATA_FRESHNESS_THRESHOLD
                 'within_range'
               else
                 'out_of_range'
               end

      IdentityJobLogSubscriber.new.logger.info(
        {
          name: 'DataFreshnessJob',
          freshness_hours: freshness_hours,
          status: status,
        }.to_json,
      )
    else
      IdentityJobLogSubscriber.new.logger.error(
        {
          name: 'DataFreshnessJob',
          error: 'No logs found!',
        }.to_json,
      )
    end

    true
  end
end
