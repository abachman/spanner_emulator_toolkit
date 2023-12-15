# frozen_string_literal: true

##
# Force a stale-open transaction on the Spanner Emulator by running this script
# and then killing it with Ctrl-C.
#
# Rerunning the script will result in a hung process followed by the "one
# transaction at a time" error.
##
require_relative "emulator_util"

$stdout.sync = true

EmulatorUtil.setup!
client = EmulatorUtil.client

loop do
  client.transaction(deadline: 3) do |tx|
    puts "starting transaction #{tx.transaction_id}"
    tx.execute "INSERT INTO Customers (Id) VALUES ('#{SecureRandom.hex(6)}')"
    sleep 0.5
    tx.execute "INSERT INTO Customers (Id) VALUES ('#{SecureRandom.hex(6)}')"
  end
rescue Google::Cloud::AbortedError => e
  puts "#{e.class} #{e.message}"
  exit 1
rescue => e
  puts "#{e.class} #{e.message}"
end
