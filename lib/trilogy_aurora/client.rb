# frozen_string_literal: true

require 'trilogy'

module TrilogyAurora
  # Trilogy Aurora wrapper
  class Client
    attr_reader :trilogy

    def initialize(options = {})
      @trilogy = ::Trilogy.new(options)
    end

    # Disconnect and re-initialize ::Trilogy
    def reconnect!
      disconnect!

      @trilogy = ::Trilogy.new(@trilogy.connection_options.dup)
    end

    # Close ::Trilogy connection
    def disconnect!
      trilogy&.close
    rescue StandardError
      nil
    end

    # Execute a ::Trilogy query, disconnecting or reconnecting after read-only errors
    # based on initialization options.
    def query(...) # rubocop:disable Metrics/AbcSize
      try_count = 0

      begin
        trilogy.query(...)
      rescue ::Trilogy::Error => e
        raise unless e.message&.include?('--read-only')

        try_count += 1

        if trilogy.connection_options[:aurora_disconnect_on_readonly]
          warn <<~WARNING.squish
            [trilogy_aurora] Database is readonly, Aurora failover event likely occured.
            Closing database connection
          WARNING
          disconnect!
        elsif try_count <= trilogy.connection_options[:aurora_max_retry]
          retry_interval_seconds = [1.5 * (try_count - 1), 10].min
          warn <<~WARNING.squish
            [trilogy_aurora] Database is readonly.
            Retry after #{retry_interval_seconds} seconds
          WARNING
          sleep retry_interval_seconds
          reconnect!
          retry
        end

        raise
      end
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
      ::Trilogy.public_send(name, ...)
    end

    # Delegate `respond_to?` to ::Trilogy.
    def self.respond_to_missing?(name, ...)
      ::Trilogy.respond_to?(name, ...)
    end

    # Delegate const reference to ::Trilogy.
    def self.const_missing(name)
      ::Trilogy.const_get(name)
    end

    # Delegate `const_defined?` to ::Trilogy.
    def self.const_defined?(name, ...)
      ::Trilogy.const_defined?(name, ...)
    end
  end
end
