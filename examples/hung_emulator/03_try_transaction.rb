require "google/cloud/spanner"

project = Google::Cloud::Spanner.new(
  project_id: ENV["SPANNER_PROJECT_ID"],
  emulator_host: ENV["SPANNER_EMULATOR_HOST"]
)
client = project.client(ENV["SPANNER_INSTANCE_ID"], ENV["SPANNER_DATABASE_ID"])

begin
  client.transaction(deadline: 5) do |tx|
    tx.execute "INSERT INTO Customers (Id) VALUES ('#{SecureRandom.hex(6)}')"
  end
rescue Google::Cloud::AbortedError => e
  exit 1
end
