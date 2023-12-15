## Illustrating the "hung transactions" problem in the Google Cloud Spanner emulator.

If a process opens a transaction on a database in the emulator and crashes without committing or rolling back, the database will not permit any future transactions.

One workaround (linked below) is to force all hung open transactions to close by listing every session on the database, creating an empty transaction on it, and then immediately rolling the transaction back.

**BUT**, if sessions are released instead of going through the empty transaction workaround, either manually or by any other background process (something in the emulator?), then they cannot be listed. This means new transactions cannot be opened on them and any transactions which were left open on them are still open. This effectively kills the database, requiring a restart of the emulator.

I've been using the workaround in a project, but still occasionally see open transactions with no sessions after returning to work the day after spending time running tests in the emulator.

### usage

setup:
```console
# setup
$ gem install google-cloud-spanner
$ docker run -p 9010:9010 -p 9020:9020 gcr.io/cloud-spanner-emulator/emulator:latest
```

run:
```console
$ sh run.sh
1..8
ok 1 - emulator is stuck
ok 2 - emulator sessions reset
ok 3 - transaction failed
ok 4 - emulator is stuck
ok 5 - emulator sessions released
not ok 6 - transaction failed
ok 7 - emulator sessions reset
not ok 8 - transaction failed
```

The test output illustrates the problem scenario:

1. a transaction is opened on the database and the process is killed until one is left hanging open
2. emulator sessions are reset by opening and rolling back an empty transaction
3. another transaction tried on the same database succeeds
4. same as 1, flail until the database is locked up
5. release emulator sessions, removing them from the emulator
6. transaction attempt fails with the `Google::Cloud::AbortedError ... The emulator only supports one transaction at a time` error
7. try resetting sessions again
8. transaction attempt still fails with the `Google::Cloud::AbortedError` error

Ideally, every transaction attempt should succeed.

### links

- [Google Cloud Spanner emulator docs](https://cloud.google.com/spanner/docs/emulator)
- [GoogleCloudPlatform/cloud-spanner-emulator](https://github.com/GoogleCloudPlatform/cloud-spanner-emulator)
- [Stuck emulator transactions issue with workaround example code](https://github.com/GoogleCloudPlatform/cloud-spanner-emulator/issues/137)
