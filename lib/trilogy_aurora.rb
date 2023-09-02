# frozen_string_literal: true

require_relative "trilogy_aurora/version"
require "trilogy"

# This module contains Trilogy, a wrapper around ::Trilogy that handles read-only errors from Aurora.
#
# It also contains the original ::Trilogy class as ORIGINAL_TRILOGY_CLASS.
module TrilogyAurora
  # A wrapper around ::Trilogy that handles read-only errors from Aurora.
  class Trilogy
    # The ::Trilogy instance.
    attr_reader :trilogy

    # Pass in any options that ::Trilogy accepts.
    #
    # Additionally, you can pass in the `aurora_max_retry` and `aurora_disconnect_on_readonly` options:
    #
    # - `aurora_max_retry` is the number of times to retry a query when it fails due to a read-only error.
    # The default is 5.
    #
    # - `aurora_disconnect_on_readonly` is a boolean that determines whether or not to disconnect from the database
    # after a read-only error is encountered.
    # The default is false.
    def initialize(opts)
      @opts = opts&.transform_keys(&:to_sym)
      @max_retry = @opts.delete(:aurora_max_retry) || 5
      @disconnect_only = @opts.delete(:aurora_disconnect_on_readonly) || false
      reconnect!
    end

    # Execute a ::Trilogy query, disconnecting or reconnecting after read-only errors
    # based on initialization options.
    def query(...)
      try_count = 0

      begin
        trilogy.query(...)
      rescue TrilogyAurora::ORIGINAL_TRILOGY_CLASS::Error => e
        raise e unless e.message&.include?("--read-only")

        try_count += 1

        if @disconnect_only
          warn(
            "[trilogy_aurora] Database is readonly, Aurora failover event likely occured, closing database connection"
          )
          disconnect!
        elsif try_count <= @max_retry
          retry_interval_seconds = [1.5 * (try_count - 1), 10].min

          warn "[trilogy_aurora] Database is readonly. Retry after #{retry_interval_seconds}seconds"
          sleep retry_interval_seconds
          reconnect!
          retry
        end

        raise e
      end
    end

    # Disconnect and re-initialize ::Trilogy
    def reconnect!
      disconnect!

      @trilogy = TrilogyAurora::ORIGINAL_TRILOGY_CLASS.new(@opts)
    end

    # Close ::Trilogy connection
    def disconnect!
      @trilogy&.close
    rescue StandardError
      nil
    end

    # Delegate instance method calls to ::Trilogy instance.
    def method_missing(name, ...)
      trilogy.public_send(name, ...)
    end

    # Delegate `respond_to?` to ::Trilogy instance.
    def respond_to_missing?(name, ...)
      trilogy.respond_to?(name, ...)
    end

    # Delegate class method calls to ::Trilogy.
    def self.method_missing(name, ...)
      TrilogyAurora::ORIGINAL_TRILOGY_CLASS.public_send(name, ...)
    end

    # Delegate `respond_to?` to ::Trilogy.
    def self.respond_to_missing?(name, ...)
      TrilogyAurora::ORIGINAL_TRILOGY_CLASS.respond_to?(name, ...)
    end

    # Delegate const reference to ::Trilogy.
    def self.const_missing(name)
      TrilogyAurora::ORIGINAL_TRILOGY_CLASS.const_get(name)
    end
  end

  # The original ::Trilogy class.
  ORIGINAL_TRILOGY_CLASS = ::Trilogy
  # Swap out the original ::Trilogy class with our wrapper (Trilogy).
  ::Trilogy = TrilogyAurora::Trilogy
end
