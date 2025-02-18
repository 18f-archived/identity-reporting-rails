class ReportMailerPreview < ActionMailer::Preview
  def fraud_metrics_report
    fraud_metrics_report = Reports::FraudMetricsReport.new(Time.zone.yesterday)

    stub_cloudwatch_client(fraud_metrics_report.fraud_metrics_lg99_report)

    ReportMailer.tables_report(
      email: 'test@example.com',
      subject: "Example Fraud Key Metrics Report - #{Time.zone.now.to_date}",
      message: fraud_metrics_report.preamble,
      attachment_format: :xlsx,
      reports: fraud_metrics_report.reports,
    )
  end

  def tables_report
    ReportMailer.tables_report(
      email: 'test@example.com',
      subject: 'Example Report',
      message: 'Sample Message',
      attachment_format: :csv,
      reports: [
        Reporting::EmailableReport.new(
          table: [
            ['Some', 'String'],
            ['a', 'b'],
            ['c', 'd'],
          ],
        ),
        Reporting::EmailableReport.new(
          float_as_percent: true,
          table: [
            [nil, 'Int', 'Float as Percent'],
            ['Row 1', 1, 0.5],
            ['Row 2', 1, 1.5],
          ],
        ),
        Reporting::EmailableReport.new(
          float_as_percent: false,
          table: [
            [nil, 'Gigantic Int', 'Float as Float'],
            ['Row 1', 100_000_000, 1.0],
            ['Row 2', 123_456_789, 1.5],
          ],
        ),
      ],
    )
  end

  private

  class FakeCloudwatchClient
    def initialize(data:)
      @data = data
    end

    def fetch(**)
      @data
    end
  end

  def stub_cloudwatch_client(report, data: [])
    class << report
      attr_accessor :_stubbed_cloudwatch_data

      def cloudwatch_client
        FakeCloudwatchClient.new(data: @_stubbed_cloudwatch_data)
      end
    end
    report._stubbed_cloudwatch_data = data
    report
  end
end
