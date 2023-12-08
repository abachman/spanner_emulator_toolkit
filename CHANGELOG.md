## [0.1.0]

Initial release.

- Global configuration with `SpannerEmulatorToolkit.configure { |config| ... }` or ENV vars
- Google::Cloud::Spanner client methods: `create_instance`, `create_database`, `drop_instance`, `drop_database`
- `reset_session!` to reset transactions all instances and databases of the configured project and emulator
