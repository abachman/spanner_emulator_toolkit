# frozen_string_literal: true

require "spec_helper"

RSpec.describe Google::Cloud::Spanner::Service do
  let(:service_instance) do
    Google::Cloud::Spanner::Service.new("project", "credentihls")
  end

  let(:response_double) do
    instance_double("Gapic::PagedEnumerable", response: [])
  end

  let(:service_service_double) do
    instance_double("Google::Cloud::Spanner::V1::Spanner::Client",
      list_sessions: response_double)
  end

  let(:database) do
    "projects/project/instances/instance/databases/database"
  end

  it "has a list_sessions method" do
    expect(service_instance).to respond_to(:list_sessions)
  end

  describe "#list_sessions" do
    before do
      allow(service_instance).to receive(:service).and_return(service_service_double)
    end

    it "returns a service response" do
      expect(service_instance.list_sessions(database:)).to respond_to(:each)
    end
  end
end
