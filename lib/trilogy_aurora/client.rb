# frozen_string_literal: true

require 'trilogy'

module TrilogyAurora
  # Trilogy Aurora wrapper
  class Client
    attr_reader :trilogy

    def initialize(options = {})
      @trilogy = TrilogyAurora::Trilogy.new(options)
    end

    # Disconnect and re-initialize TrilogyAurora::Trilogy
    def reconnect!
      disconnect!

      @trilogy = TrilogyAurora::Trilogy.new(@trilogy.connection_options.dup)
    end

    # Close TrilogyAurora::Trilogy connection
    def disconnect!
      trilogy&.close
    rescue StandardError
      nil
    end

    # Execute a TrilogyAurora::Trilogy query, disconnecting or reconnecting after read-only errors
    # based on initialization options.
    def query(...) # rubocop:disable Metrics/AbcSize
      try_count = 0

      begin
        trilogy.query(...)
      rescue TrilogyAurora::Trilogy::Error => e
        raise unless e.message&.include?('--read-only')

        try_count += 1

        if trilogy.connection_options[:aurora_disconnect_on_readonly]
          warn <<~WARNING
            [trilogy_aurora] Database is readonly, Aurora failover event likely occured. \
            Closing database connection
          WARNING
          disconnect!
        elsif try_count <= trilogy.connection_options[:aurora_max_retry]
          retry_interval_seconds = [1.5 * (try_count - 1), 10].min
          warn <<~WARNING
            [trilogy_aurora] Database is readonly. \
            Retry after #{retry_interval_seconds} seconds
          WARNING
          sleep retry_interval_seconds
          reconnect!
          retry
        end

        raise
      end
    end

    # Delegate instance method calls to TrilogyAurora::Trilogy instance.
    def method_missing(...)
      trilogy.public_send(...)
    end

    # Delegate `respond_to?` to TrilogyAurora::Trilogy instance.
    def respond_to_missing?(...)
      trilogy.respond_to?(...)
    end

    # Delegate class method calls to TrilogyAurora::Trilogy.
    def self.method_missing(...)
      TrilogyAurora::Trilogy.public_send(...)
    end

    # Delegate `respond_to?` to TrilogyAurora::Trilogy.
    def self.respond_to_missing?(...)
      TrilogyAurora::Trilogy.respond_to?(...)
    end

    # Delegate const reference to TrilogyAurora::Trilogy.
    def self.const_missing(...)
      TrilogyAurora::Trilogy.const_get(...)
    end

    # Delegate `const_defined?` to TrilogyAurora::Trilogy.
    def self.const_defined?(...)
      TrilogyAurora::Trilogy.const_defined?(...)
    end
  end

  Trilogy = Object.send(:remove_const, :Trilogy)
end

Trilogy = TrilogyAurora::Client
