# frozen_string_literal: true

require 'reporting/authentication_report'

module Reports
  class AuthenticationReport < BaseReport
    REPORT_NAME = 'authentication-report'

    attr_accessor :report_date

    def perform(report_date)
      unless IdentityConfig.store.redshift_sia_v3_enabled
        Rails.logger.warn 'Redhsift SIA V3 is disabled'
        return false
      end

      return unless IdentityConfig.store.s3_reports_enabled

      self.report_date = report_date

      report_configs.each do |report_hash|
        reports = weekly_authentication_reports(report_hash['issuers'])
        reports.each do |report|
          table    = report.fetch(:table)
          filename = report.fetch(:filename)
          upload_to_s3(table, report_name: filename)
        end
      end
    end

    def weekly_authentication_reports(issuers)
      Reporting::AuthenticationReport.new(
        issuers:,
        time_range: report_date.all_week,
      ).as_reports
    end

    private

    def upload_to_s3(report_body, report_name: nil)
      _latest, path = generate_s3_paths(REPORT_NAME, 'csv', subname: report_name, now: report_date)

      if bucket_name.present?
        upload_file_to_s3_bucket(
          path: path,
          body: csv_file(report_body),
          content_type: 'text/csv',
          bucket: bucket_name,
        )
      end
    end

    def report_configs
      IdentityConfig.store.weekly_auth_funnel_report_config
    end

    def csv_file(report_array)
      CSV.generate do |csv|
        report_array.each do |row|
          csv << row
        end
      end
    end
  end
end
