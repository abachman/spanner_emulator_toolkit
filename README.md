# SpannerEmulatorToolkit

Peform some simple or otherwise impossible tasks with [the Cloud Spanner Emulator][emulator], with specific focus on resetting all session transactions for a given Emulator.

## Installation

Install the gem and add to the application's Gemfile by executing:

```console
$ bundle add spanner_emulator_toolkit
```

If bundler is not being used to manage dependencies, install the gem by executing:

```console
$ gem install spanner_emulator_toolkit
```

## Usage

### Configuration

All functionality require configuration first. All required settings have reasonably safe defaults and can be set through environment variables.

| Option | Description | Default | Required | Env |
| --- | --- | --- | --- | --- |
| `project_id` | The project ID to use. | `"example-project"` | **Yes** | `SPANNER_PROJECT_ID` |
| `instance_id` | The instance ID to use. | `"example-instance"` | no | `SPANNER_PROJECT_ID` |
| `project_id` | The database ID to use. | `"example-database"` | no | `SPANNER_DATABASE_ID` |
| `emulator_host` | Local hostname for the [cloud-spanner-emulator][emulator]. | `"localhost:9010"` | **Yes** | `SPANNER_EMULATOR_HOST` |
| `logger` | A Ruby Logger instance. | `Logger.new(STDOUT)` | no | |
| `log_level` | The log level to use for the logger. | `Logger::FATAL` | no | |
| `schema` | A raw SQL schema to use when creating the database. | `nil` | no | |

```ruby
# if all you're doing is resetting sessions
SpannEmulatorToolkit.configure do |config|
  config.project_id = "test-project"
  config.emulator_host = "localhost:9010"
end

# if you're creating a specific instance and database
SpannEmulatorToolkit.configure do |config|
  config.project_id = "test-project"
  config.instance_id = "test-instance"
  config.database_id = "test-database"
  config.emulator_host = "localhost:9010"
end

# If you want to use an existing logger. Nothing too interesting is produced by
# the library, just debug logging.
SpannEmulatorToolkit.configure do |config|
  config.logger = Rails.logger
end

# if you want to see debug logs on STDOUT
SpannEmulatorToolkit.configure do |config|
  config.log_level = Logger::DEBUG
end

# to create a database with a schema
SpannEmulatorToolkit.configure do |config|
  config.schema = <<~SQL
    CREATE TABLE users (
      id INT64 NOT NULL,
      username STRING(255) NOT NULL,
      name STRING(255) NOT NULL
    ) PRIMARY KEY (id)
  SQL
end
```

### Client methods

#### Instance and Database Management

Helper methods to work with Spanner instances and databases in the emulator.

Creating:

```ruby
# create the configured instance
SpannerEmulatorToolkit.create_instance

# create the configured instance and database
SpannerEmulatorToolkit.create_database
```

And dropping:

```ruby
# drop the configured instance and all its databases
SpannerEmulatorToolkit.drop_instance

# just drop the configured database
SpannerEmulatorToolkit.drop_database
```

#### Getting a Google::Cloud::Spanner::Client

The toolkit provides a simple wrapper around Spanner client initialization. It is not intended to be a complete replacement for the client, just a wrapper around some common patterns in prototyping.

[Google's documentation](https://cloud.google.com/ruby/docs/reference/google-cloud-spanner/latest/index.html) for the Spanner client is a good place to start.

```ruby
# Google::Cloud::Spanner::Client
client = SpannerEmulatorToolkit.client

client.commit do |c|
  c.update "users", [{ id: 1, username: "charlie94", name: "Charlie" }]
  c.insert "users", [{ id: 2, username: "harvey00", name: "Harvey" }]
end

results = client.read "users", [:id, :name], keys: 1..5
results.rows.each do |row|
  puts "User #{row[:id]} is #{row[:name]}"
end
```

Or more specific classes from the [google-cloud-spanner](https://github.com/googleapis/ruby-spanner/) gem:

```ruby
# Google::Cloud::Spanner::Project
SpannerEmulatorToolkit.project

# Google::Cloud::Spanner::Database
SpannerEmulatorToolkit.database
SpannerEmulatorToolkit.database_exists?
SpannerEmulatorToolkit.database_path # the full "projects/.../instances/.../databases/..." path

# Google::Cloud::Spanner::Instance
SpannerEmulatorToolkit.instance
SpannerEmulatorToolkit.instance_exists?
```

### Reset all session transactions

Why this gem exists in the first place: to reset all sessions on all databases in all instances for the configured project in the emulator.

```ruby
SpannerEmulatorToolkit.reset_sessions!
```

**Background**: [GoogleCloudPlatform/cloud-spanner-emulator#137](https://github.com/GoogleCloudPlatform/cloud-spanner-emulator/issues/137)

The Spanner Local Emulator has a known failure mode in which transactions left open by a process that has crashed are not cleaned up. This will cause the emulator to reject all future transactions.

This can be fixed by restarting the emulator, but that drops all your databases and data which can be a huge pain in a large project.

This tool will reset all open transactions in the emulator so you can continue working.

Useful for development and any environment where you're killing processes (like test suites) which may have a pending transaction open when they are killed.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Run `rake rubocop` to run the linter before committing changes.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Running the examples

Before running an example, you'll need to [start the emulator][emulator]. The easiest way to do that is [with the pre-built Docker image](https://github.com/GoogleCloudPlatform/cloud-spanner-emulator#via-pre-built-docker-image).

```console
$ docker pull gcr.io/cloud-spanner-emulator/emulator
$ docker run -p 9010:9010 -p 9020:9020 gcr.io/cloud-spanner-emulator/emulator
```

Or through docker compose:

```yaml
services:
  google-cloud-spanner:
    image: gcr.io/cloud-spanner-emulator/emulator:latest
    ports:
      - "9010:9010"
      - "9020:9020"

# docker compose up google-cloud-spanner
```

There are some examples in the `examples` directory. These are not run as part of the test suite, but can be run manually.

```console
$ bundle exec ruby examples/create_instance.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abachman/spanner_emulator_toolkit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/abachman/spanner_emulator_toolkit/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SpannerEmulatorToolkit project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/abachman/spanner_emulator_toolkit/blob/main/CODE_OF_CONDUCT.md).


[emulator]: https://github.com/GoogleCloudPlatform/cloud-spanner-emulator