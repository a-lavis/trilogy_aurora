# frozen_string_literal: true

require 'trilogy_aurora/version'
require 'trilogy_aurora/client'

if defined?(ActiveRecord)
  require 'active_record/connection_adapters/trilogy_adapter'

  module ActiveRecord # rubocop:disable Style/Documentation
    module ConnectionAdapters
      # Use TrilogyAurora::Client instead of ::Trilogy
      class TrilogyAuroraAdapter < TrilogyAdapter
        class << self
          def new_client(config)
            config[:ssl_mode] = parse_ssl_mode(config[:ssl_mode]) if config[:ssl_mode]
            TrilogyAurora::Client.new(config)
          rescue ::Trilogy::Error => e
            raise translate_connect_error(config, e)
          end
        end
      end
    end

    # Swap TrilogyAdapter with TrilogyAuroraAdapter
    ConnectionAdapters.send(:remove_const, :TrilogyAdapter)
    ConnectionAdapters.const_set(:TrilogyAdapter, ConnectionAdapters::TrilogyAuroraAdapter)
  end
end
