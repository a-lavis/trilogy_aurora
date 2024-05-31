# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in trilogy_aurora.gemspec
gemspec

group :development do
  # If the TRILOGY_VERSION environment variable is set, it should be a minor version.
  trilogy_version = ENV.fetch("TRILOGY_VERSION", nil)
  gem "trilogy", "~> #{trilogy_version}.0" if trilogy_version&.length&.positive?

  gem "debug"
  gem "irb"
  gem "rake", "~> 13.1"
  gem "rspec", "~> 3.13"
  gem "rubocop", "~> 1.64", require: false
  gem "rubocop-rake", "~> 0.6", require: false
  gem "rubocop-rspec", "~> 2.28", require: false
  gem "simplecov", "~> 0.22", require: false
end
