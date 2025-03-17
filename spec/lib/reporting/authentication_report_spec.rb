require 'rails_helper'
require 'reporting/authentication_report'

RSpec.describe Reporting::AuthenticationReport do
  let(:issuer)               { 'my:example:issuer' }
  let(:time_range)           { Date.new(2022, 1, 1).all_day }
  let(:cloudwatch_timestamp) { Time.zone.at(rand(time_range.begin.to_i..time_range.end.to_i)).utc }

  subject(:report) { Reporting::AuthenticationReport.new(issuers: [issuer], time_range:) }

  let(:events) do
    [
      # finishes funnel
      { 'user_id' => 'user1', 'name' => 'OpenID Connect: authorization request' },
      { 'user_id' => 'user1', 'name' => 'User Registration: Email Confirmation' },
      { 'user_id' => 'user1', 'name' => 'User Registration: 2FA Setup visited' },
      { 'user_id' => 'user1', 'name' => 'User Registration: User Fully Registered' },
      { 'user_id' => 'user1', 'name' => 'SP redirect initiated' },

      # first 3 steps
      { 'user_id' => 'user2', 'name' => 'OpenID Connect: authorization request' },
      { 'user_id' => 'user2', 'name' => 'User Registration: Email Confirmation' },
      { 'user_id' => 'user2', 'name' => 'User Registration: 2FA Setup visited' },
      { 'user_id' => 'user2', 'name' => 'User Registration: User Fully Registered' },

      # first 2 steps
      { 'user_id' => 'user3', 'name' => 'OpenID Connect: authorization request' },
      { 'user_id' => 'user3', 'name' => 'User Registration: Email Confirmation' },
      { 'user_id' => 'user3', 'name' => 'User Registration: 2FA Setup visited' },

      # first step only
      { 'user_id' => 'user4', 'name' => 'OpenID Connect: authorization request' },
      { 'user_id' => 'user4', 'name' => 'User Registration: Email Confirmation' },

      # already existing user, just signing in
      { 'user_id' => 'user5', 'name' => 'OpenID Connect: authorization request' },
      { 'user_id' => 'user5', 'name' => 'SP redirect initiated' },
    ]
  end

  before do
    events.each do |event|
      Event.create!(
        id: SecureRandom.uuid,
        message: event,
        name: event['name'],
        user_id: event['user_id'],
        new_event: true,
        success: true,
        service_provider: issuer,
        cloudwatch_timestamp: cloudwatch_timestamp,
      )
    end
  end

  describe '#as_tables' do
    it 'generates the tabular csv data' do
      expect(report.as_tables).to eq expected_tables
    end
  end

  describe '#as_reports' do
    it 'adds a "first row" hash with a title for tables_report mailer' do
      reports = report.as_reports
      aggregate_failures do
        reports.each do |report|
          expect(report[:title]).to be_present
          expect(report[:table]).to be_present
        end
      end
    end
  end

  describe '#to_csvs' do
    it 'generates a csv' do
      csv_string_list = report.to_csvs
      expect(csv_string_list.count).to be 2

      csvs = csv_string_list.map { |csv| CSV.parse(csv) }

      aggregate_failures do
        csvs.map(&:to_a).zip(expected_tables(strings: true)).each do |actual, expected|
          expect(actual).to eq(expected)
        end
      end
    end
  end

  def expected_tables(strings: false)
    [
      [
        ['Report Timeframe', "#{time_range.begin} to #{time_range.end}"],
        ['Report Generated', Date.today.to_s], # rubocop:disable Rails/Date
        ['Issuer', issuer],
        ['Total # of IAL1 Users', strings ? '2' : 2],
      ],
      [
        ['Metric', 'Number of accounts', '% of total from start'],
        ['New Users Started IAL1 Verification', strings ? '4' : 4, '100.0%'],
        ['New Users Completed IAL1 Password Setup', strings ? '3' : 3, '75.0%'],
        ['New Users Completed IAL1 MFA', strings ? '2' : 2, '50.0%'],
        ['New IAL1 Users Consented to Partner', strings ? '1' : 1, '25.0%'],
      ],
    ]
  end
end
