# frozen_string_literal: true

require "spec_helper"

RSpec.describe SpannerEmulatorToolkit do
  let(:instance_id) { "test-instance-#{Time.now.to_i}" }
  let(:database_id) { "test-database-#{Time.now.to_i}" }
  let(:schema_file) { File.expand_path("./schema.sql", __dir__) }

  RSpec.shared_examples "no database available" do
    it "client raises an error" do
      expect { described_class.client }.to raise_error(Google::Cloud::NotFoundError)
    end
  end

  RSpec.shared_examples "no instance available" do
    it_behaves_like "no database available"

    it "instance returns nil" do
      expect(described_class.instance).to be_nil
    end
  end

  RSpec.shared_examples "instance available" do
    it "provides a Spanner instance connection" do
      expect(described_class.instance).to(
        be_a(Google::Cloud::Spanner::Instance)
      )
    end
  end

  RSpec.shared_examples "database available" do
    it_behaves_like "instance available"

    it "provides a Spanner database connection" do
      expect(described_class.database).to(
        be_a(Google::Cloud::Spanner::Database)
      )
    end
  end

  before do
    # randomizing instance_id and database_id each run
    SpannerEmulatorToolkit.configure do |config|
      config.project_id = "test-project"
      config.instance_id = instance_id
      config.database_id = database_id
    end

    # reset the client memoization
    described_class.reset_client
  end

  after do
    described_class.drop_instance
  end

  it "provides a Spanner project connection" do
    expect(described_class.project).to(
      be_a(Google::Cloud::Spanner::Project)
    )
  end

  subject { described_class }

  it_behaves_like "no instance available"

  context "with an existing instance" do
    before do
      described_class.create_instance
    end

    it_behaves_like "no database available"
    it_behaves_like "instance available"

    it { is_expected.to be_instance_exists }
    it { is_expected.to_not be_database_exists }

    it "drops the instance" do
      expect(described_class).to be_instance_exists
      described_class.drop_instance
      expect(described_class).to_not be_instance_exists
    end

    context "with an existing database" do
      before do
        described_class.create_database
      end

      after do
        described_class.drop_database
      end

      it { is_expected.to be_instance_exists }
      it { is_expected.to be_database_exists }

      it_behaves_like "database available"

      it "provides a Spanner client" do
        expect(described_class.client).to(
          be_a(Google::Cloud::Spanner::Client)
        )
      end

      it "drops the database" do
        expect(described_class).to be_database_exists
        described_class.drop_database
        expect(described_class).to_not be_database_exists
      end
    end
  end

  context "with stubbed APIs" do
    let(:mock_instance_job) { instance_double(Google::Cloud::Spanner::Instance::Job, wait_until_done!: true) }
    let(:mock_database_job) { instance_double(Google::Cloud::Spanner::Database::Job, wait_until_done!: true) }
    let(:mock_instance) { instance_double(Google::Cloud::Spanner::Instance, create_database: mock_database_job, delete: true) }
    let(:mock_project) { instance_double(Google::Cloud::Spanner::Project, create_instance: mock_instance_job) }

    describe "#create_instance" do
      before do
        allow(described_class).to receive(:project).and_return(mock_project)
      end

      it "creates an instance if none exists" do
        allow(described_class).to receive(:instance_exists?).and_return(false)
        described_class.create_instance
        expect(mock_project).to have_received(:create_instance)
      end
    end

    describe "#create_database" do
      before do
        allow(described_class).to receive(:project).and_return(mock_project)
        allow(described_class).to receive(:instance).and_return(mock_instance)
      end

      it "creates an instance if none exists" do
        allow(described_class).to receive(:instance_exists?).and_return(false)
        allow(described_class).to receive(:database_exists?).and_return(false)

        described_class.create_database

        expect(mock_project).to have_received(:create_instance)
        expect(mock_instance).to have_received(:create_database)
      end

      it "creates a database if none exists" do
        allow(described_class).to receive(:instance_exists?).and_return(true)
        allow(described_class).to receive(:database_exists?).and_return(false)

        described_class.create_database
        expect(mock_instance).to have_received(:create_database)
      end
    end
  end
end
