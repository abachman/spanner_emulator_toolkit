# to start the emulator in docker:
#
#   docker run -p 9010:9010 -p 9020:9020 gcr.io/cloud-spanner-emulator/emulator:latest
#

export SPANNER_PROJECT_ID="example-project"
export SPANNER_INSTANCE_ID="example-instance"
export SPANNER_DATABASE_ID="example-database"
export SPANNER_EMULATOR_HOST="localhost:9010"

background_pid=
function kill_background_job {
  if [ -z "$background_pid" ]; then
    return
  fi
  kill -9 $background_pid > /dev/null 2>&1
  wait $background_pid >/dev/null 2>&1
}
function echo_and_kill {
  echo 'killing background job'
  kill_background_job
}
trap kill_background_job EXIT

function check_for_emulator {
  if ! curl -s localhost:9020/v1/projects > /dev/null
  then
    echo 'emulator is not running, start with:'
    echo
    echo '   docker run -p 9010:9010 gcr.io/cloud-spanner-emulator/emulator'
    echo
    exit 1
  fi
}

function force_open_transaction {
  echo '' > transaction-worker.log
  until grep "Google::Cloud::AbortedError" transaction-worker.log > /dev/null
  do
    # start transaction worker in the backgroun
    ruby 01_force_transaction_error.rb > transaction-worker.log 2>&1 &
    background_pid=$!
    # sleep long enough for any attempted transaction to reach the deadline
    sleep 7
    # unceremoniously kill the transaction worker
    kill_background_job
  done

  echo "ok $1 - emulator is stuck"
}

function reset_sessions {
  if ruby 02a_session_reset.rb; then
    echo "ok $1 - emulator sessions reset"
  else
    echo "not ok $1 - emulator sessions could not be reset"
  fi
}

function release_sessions {
  if ruby 02b_session_release.rb; then
    echo "ok $1 - emulator sessions released"
  else
    echo "not ok $1 - emulator sessions could not be released"
  fi
}

function try_transaction {
  if ruby 03_try_transaction.rb
  then
    echo "ok $1 - transaction succeeded"
  else
    echo "not ok $1 - transaction failed"
  fi
}

check_for_emulator
echo '1..8'
force_open_transaction '1'
reset_sessions '2'
try_transaction '3' # this step only fails when the emulator is stuck and sessions are gone
force_open_transaction '4'
release_sessions '5'
try_transaction '6'
reset_sessions '7'
try_transaction '8'
