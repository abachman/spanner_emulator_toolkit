# frozen_string_literal: true

require_relative "lib/spanner_emulator_toolkit/version"

Gem::Specification.new do |spec|
  spec.name = "spanner_emulator_toolkit"
  spec.version = SpannerEmulatorToolkit::VERSION
  spec.authors = ["Adam Bachman"]
  spec.email = ["adam.bachman@gmail.com"]

  spec.summary = "Google Cloud Spanner emulator toolkit"
  spec.description = "Helpers for working with the Google Cloud Spanner emulator."
  spec.homepage = "https://github.com/abachman/spanner_emulator_toolkit"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/abachman/spanner_emulator_toolkit"
  spec.metadata["changelog_uri"] = "https://github.com/abachman/spanner_emulator_toolkit/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "google-cloud-spanner", "~> 2.10"
  spec.add_dependency "concurrent-ruby", "~> 1.2"
end
