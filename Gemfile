# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in trilogy_aurora.gemspec
gemspec

trilogy_version = ENV.fetch("TRILOGY_VERSION", false)
gem "trilogy", "~> #{trilogy_version}" if trilogy_version

group :development do
  gem "debug"
  gem "irb"
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.0"
  gem "rubocop", "~> 1.56", require: false
  gem "rubocop-rake", "~> 0.6", require: false
  gem "rubocop-rspec", "~> 2.24", require: false
  gem "simplecov", "~> 0.22", require: false
end
