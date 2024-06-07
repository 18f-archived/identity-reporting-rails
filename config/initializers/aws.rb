# frozen_string_literal: true

pattern =
  ':client_class :http_response_status_code :time :retries :operation [:error_class :error_message]'
log_formatter = Aws::Log::Formatter.new(pattern)

Aws.config.update(
  region: Identity::Hostdata.config.aws_region,
  logger: Rails.application.config.logger,
  log_formatter: log_formatter,
)
