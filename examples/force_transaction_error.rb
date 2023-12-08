# frozen_string_literal: true

##
# Force a stale-open transaction on the Spanner Emulator by running this script
# and then killing it with Ctrl-C.
#
# Rerunning the script will result in a hung process followed by the "one
# transaction at a time" error.
#
##
require "google/cloud/spanner"

PROJECT_ID = "test-project"
INSTANCE_ID = "test-instance"
DATABASE_ID = "test-database"
EMULATOR_HOST = "localhost:9010"

schema = "CREATE TABLE Customers (Id STRING(36) NOT NULL) PRIMARY KEY (Id)"
project = Google::Cloud::Spanner.new(
  project_id: PROJECT_ID,
  emulator_host: EMULATOR_HOST
)
unless project.instance(INSTANCE_ID)
  project.create_instance(INSTANCE_ID, name: INSTANCE_ID, nodes: 1).wait_until_done!
end
unless project.instance(INSTANCE_ID).database(DATABASE_ID)
  project.instance(INSTANCE_ID).create_database(DATABASE_ID, statements: [schema]).wait_until_done!
end
client = project.client(INSTANCE_ID, DATABASE_ID)
puts
puts "starting transactions on #{client.database.path}"
puts "  press Ctrl-C to stop"
puts
loop do
  client.transaction(deadline: 5) do |tx|
    tx.execute "INSERT INTO Customers (Id) VALUES ('#{SecureRandom.hex(6)}')"
    sleep 0.5
    print "."
  end
end
