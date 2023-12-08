require "spec_helper"
require "concurrent"
require "securerandom"

RSpec.describe SpannerEmulatorToolkit do
  let(:instance_id) { "test-database-#{Time.now.to_i}" }
  let(:database_id) { "test-database-#{Time.now.to_i}" }
  let(:client) { SpannerEmulatorToolkit.client }
  let(:worker_pool) { Concurrent::CachedThreadPool.new }
  let(:deadline_error_reports) { Concurrent::Array.new }
  let(:success_reports) { Concurrent::Hash.new }
  let(:cancellation_error_reports) { Concurrent::Array.new }
  let(:unexpected_error_reports) { Concurrent::Array.new }
  let(:do_work) { Concurrent::AtomicBoolean.new(true) }

  before do
    described_class.configure do |config|
      config.project_id = "test-project"
      config.instance_id = instance_id
      config.database_id = database_id
      config.emulator_host = "localhost:9010"
      config.schema = File.read(File.expand_path("../schema.sql", __dir__))
      config.log_level = Logger::ERROR
    end
    described_class.create_database
  end

  after do
    worker_pool.shutdown
    described_class.drop_instance
  end

  def log(msg)
    puts msg
  end

  def activity(n: nil)
    client = described_class.client
    is_worker = !n.nil?

    loop do
      client.transaction(deadline: 0.5) do |tx|
        cid = SecureRandom.hex(16)
        tx.execute "INSERT INTO Customers (Id) VALUES ('#{cid}')"
        sleep(0.3)
        success_reports[n] ||= []
        success_reports[n] << cid
      end

      break unless is_worker && do_work.value
    rescue Google::Cloud::AbortedError => e
      deadline_error_reports << {n:, e:, deadline: true}
      raise e
    rescue Google::Cloud::FailedPreconditionError => e
      cancellation_error_reports << {n:, e:, deadline: false}
      raise e
    rescue => e
      unexpected_error_reports << {n:, e:, deadline: false}
      raise e
    end
  end

  def stop_workers
    do_work.make_false
    worker_pool.shutdown
    worker_pool.wait_for_termination
  end

  it "connects to the database and resets active sessions" do
    3.times do |n|
      worker_pool.post do
        activity(n:)
      end
    end

    # pause outer loop to allow workers to start working (and failing)
    sleep 2

    # there have been transaction timeout errors
    expect(deadline_error_reports).to_not be_empty

    # but there have also been successful transactions (first worker to succeed wins)
    expect(success_reports).to_not be_empty

    # active worker is still running, new transactions still fail
    expect {
      expect {
        activity
      }.to raise_error(Google::Cloud::AbortedError)
    }.to change(deadline_error_reports, :size).by(1)

    # reset sessions
    described_class.reset_sessions!

    # transaction errors are gone
    expect { activity }.to_not raise_error
    expect(success_reports[nil]).to_not be_empty

    stop_workers

    # worker that was in the middle of a transaction should have been cancelled
    expect(cancellation_error_reports).to_not be_empty

    # no lingering transaction errors
    expect {
      activity
    }.to change(success_reports[nil], :size).by(1)
  end
end
