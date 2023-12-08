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

PROJECT_ID = "example-project"
INSTANCE_ID = "example-instance"
DATABASE_ID = "example-database"
EMULATOR_HOST = "localhost:9010"

project = Google::Cloud::Spanner.new(
  project_id: PROJECT_ID,
  emulator_host: EMULATOR_HOST
)
unless project.instance(INSTANCE_ID)
  project.create_instance(INSTANCE_ID, name: INSTANCE_ID, nodes: 1).wait_until_done!
end
unless project.instance(INSTANCE_ID).database(DATABASE_ID)
  schema = "CREATE TABLE Customers (Id STRING(36) NOT NULL) PRIMARY KEY (Id)"
  project.instance(INSTANCE_ID).create_database(DATABASE_ID, statements: [schema]).wait_until_done!
end
client = project.client(INSTANCE_ID, DATABASE_ID)
puts
puts "| starting transactions on #{client.database.path}"
puts "| press \e[1mCtrl-C\e[0m to interrupt, rerun until you get a 'one transaction at a time' error"
puts "| then run examples/session_reset.rb to clear the hung transaction"
puts
loop do
  client.transaction(deadline: 5) do |tx|
    tx.execute "INSERT INTO Customers (Id) VALUES ('#{SecureRandom.hex(6)}')"
    sleep 0.5
    print "."
    tx.execute "INSERT INTO Customers (Id) VALUES ('#{SecureRandom.hex(6)}-2')"
  end
end
