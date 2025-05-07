# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

SimpleCov.at_exit do
  SimpleCov.result.format!

  if SimpleCov.result.covered_percent < 100
    puts <<~ERR
      \e[31m
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      Coverage is under 100%. See `coverage/index.html`
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      \e[0m
    ERR
    abort
  end
end

require 'trilogy_aurora'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus
end
