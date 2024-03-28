require 'rails_helper'

RSpec.describe IdentityJobLogSubscriber, type: :job do
  subject(:subscriber) { IdentityJobLogSubscriber.new }

  it 'logs events' do
    expect(Rails.logger).to receive(:info) do |str|
      msg = JSON.parse(str, symbolize_names: true)
      expect(msg).to eq(
        name: 'queue_metric.good_job',
      )
    end

    HeartbeatJob.new.perform
  end

  describe '#enqueue_retry' do
    it 'formats retry message' do
      event = double(
        'RetryEvent',
        payload: { wait: 1, job: double('Job', job_id: '1', queue_name: 'Default', arguments: []) },
        duration: 1,
        name: 'TestEvent',
      )

      hash = subscriber.enqueue_retry(event)
      expect(hash[:wait_ms]).to eq 1000
      expect(hash[:duration_ms]).to eq 1
    end

    it 'includes exception if there is a failure' do
      job = double('Job', job_id: '1', queue_name: 'Default', arguments: [])
      allow(job.class).to receive(:warning_error_classes).and_return([])

      event = double(
        'RetryEvent',
        payload: {
          wait: 1,
          job: job,
          error: double('Exception'),
        },
        duration: 1,
        name: 'TestEvent',
      )

      hash = subscriber.enqueue_retry(event)
      expect(hash[:exception_class]).to_not be_nil
    end
  end

  describe '#enqueue' do
    let(:event_uuid) { SecureRandom.uuid }
    let(:now) { Time.zone.now }
    let(:job) { HeartbeatJob.new }

    it 'does not report the duplicate key error as an exception' do
      event = ActiveSupport::Notifications::Event.new(
        'enqueue.active_job',
        now,
        now,
        event_uuid,
        job: job,
        exception_object: ActiveRecord::RecordNotUnique.new(<<~ERR),
          PG::UniqueViolation: ERROR: duplicate key value violates unique constraint "index_good_jobs_on_cron_key_and_cron_at"
          DETAIL: Key (cron_key, cron_at)=(heartbeat_job, 2022-01-28 17:35:00) already exists.
        ERR
      )

      expect(subscriber).to_not receive(:error)
      expect(subscriber).to receive(:warn) do |str|
        payload = JSON.parse(str, symbolize_names: true)

        expect(payload).to_not have_key(:exception_class)
        expect(payload).to_not have_key(:exception_message)

        expect(payload).to match(
          duration_ms: kind_of(Numeric),
          exception_class_warn: 'ActiveRecord::RecordNotUnique',
          exception_message_warn: /(cron_key, cron_at)/,
          job_class: 'HeartbeatJob',
          job_id: job.job_id,
          name: 'enqueue.active_job',
          queue_name: kind_of(String),
          timestamp: kind_of(String),
          trace_id: nil,
          log_filename: 'workers.log',
        )
      end

      subscriber.enqueue(event)
    end
  end

  describe '#enqueue_at' do
    let(:event_uuid) { SecureRandom.uuid }
    let(:now) { Time.zone.now }
    let(:job) { HeartbeatJob.new }

    it 'does report the duplicate key error as an exception' do
      event = ActiveSupport::Notifications::Event.new(
        'enqueue.active_job',
        now,
        now,
        event_uuid,
        job: job,
        exception_object: ActiveRecord::RecordNotUnique.new(<<~ERR),
          PG::UniqueViolation: ERROR: duplicate key value violates unique constraint "index_good_jobs_on_cron_key_and_cron_at"
          DETAIL: Key (cron_key, cron_at)=(heartbeat_job, 2022-01-28 17:35:00) already exists.
        ERR
      )

      expect(subscriber).to receive(:error) do |str|
        payload = JSON.parse(str, symbolize_names: true)

        expect(payload).to have_key(:exception_class)
        expect(payload).to have_key(:exception_message)
      end

      subscriber.enqueue_at(event)
    end

    it 'is compatible with job classes that do not inherit from ApplicationJob' do
      # rubocop:disable Rails/ApplicationJob
      sample_job_class = Class.new(ActiveJob::Base) do
        def perform(_); end
      end
      # rubocop:enable Rails/ApplicationJob

      job = sample_job_class.new

      event = ActiveSupport::Notifications::Event.new(
        'enqueue.active_job',
        now,
        now,
        event_uuid,
        job: job,
        exception_object: Errno::ECONNREFUSED.new,
      )

      subscriber.enqueue_at(event)
    end
  end
end
