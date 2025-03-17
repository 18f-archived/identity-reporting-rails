require 'rails_helper'

RSpec.describe Reports::AuthenticationReport do
  let(:issuer)                          { 'issuer1' }
  let(:issuers)                         { [issuer] }
  let(:report_date)                     { Date.new(2023, 12, 25) }
  let(:time_range)                      { report_date.all_week }
  let(:email)                           { 'partner.name@example.com' }
  let(:name)                            { 'Partner Name' }
  let(:email_confirmation)              { 100 }
  let(:two_fa_setup_visited)            { 85 }
  let(:user_fully_registered)           { 80 }
  let(:sp_redirect_initiated_new_users) { 75 }
  let(:s3_report_bucket_prefix)         { 'reports-bucket' }
  subject(:report) { Reports::AuthenticationReport.new(report_date) }
  let(:report_folder) do
    'int/authentication-report/2023/2023-12-25.authentication-report'
  end

  let(:expected_s3_paths) do
    [
      "#{report_folder}/authentication_overview.csv",
      "#{report_folder}/authentication_funnel_metrics.csv",
    ]
  end

  let(:report_configs) do
    [
      {
        'name' => name,
        'issuers' => issuers,
        'emails' => [email],
      },
    ]
  end

  let(:s3_metadata) do
    {
      body: anything,
      content_type: 'text/csv',
      bucket: 'reports-bucket.1234-us-west-1',
    }
  end

  let(:mocked_reports) do
    [
      {
        title: 'Overview',
        table: mock_overview_table,
        filename: 'authentication_overview',
      },
      {
        title: 'Authentication Funnel Metrics',
        table: mock_funnel_metrics_table,
        filename: 'authentication_funnel_metrics',
      },
    ]
  end

  let(:mock_overview_table) do
    [
      ['Report Timeframe', "#{time_range.begin} to #{time_range.end}"],
      ['Report Generated', Time.zone.today.to_s],
      ['Issuer', issuers.join(', ')],
      ['Total # of IAL1 Users', 10],
    ]
  end

  let(:mock_funnel_metrics_table) do
    [
      ['Metric', 'Number of accounts', '% of total from start'],
      [
        'New Users Started IAL1 Verification', email_confirmation,
        '100.0%'
      ],
      [
        'New Users Completed IAL1 Password Setup',
        two_fa_setup_visited,
        '85.0%',
      ],
      [
        'New Users Completed IAL1 MFA',
        user_fully_registered,
        '20.0%',
      ],
      [
        'New IAL1 Users Consented to Partner',
        sp_redirect_initiated_new_users,
        '75.0%',
      ],
    ]
  end

  before do
    allow(IdentityConfig.store).to receive(:s3_reports_enabled).and_return(true)
    allow(IdentityConfig.store).to receive(:weekly_auth_funnel_report_config) { report_configs }
    allow(Identity::Hostdata).to receive(:env).and_return('int')
    allow(Identity::Hostdata).to receive(:aws_account_id).and_return('1234')
    allow(Identity::Hostdata).to receive(:aws_region).and_return('us-west-1')
    allow(IdentityConfig.store).to receive(:s3_report_bucket_prefix).
      and_return(s3_report_bucket_prefix)

    Aws.config[:s3] = {
      stub_responses: {
        put_object: {},
      },
    }

    allow(report).to receive(:weekly_authentication_reports).with(issuers).
      and_return(mocked_reports)
  end

  it 'uploads a file to S3 based on the report date' do
    expected_s3_paths.each do |path|
      expect(subject).to receive(:upload_file_to_s3_bucket).with(
        path: path,
        **s3_metadata,
      ).exactly(1).time.and_call_original
    end

    report.perform(report_date)
  end
end
