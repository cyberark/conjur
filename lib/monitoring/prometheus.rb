require 'prometheus/client'
require 'prometheus/client/data_stores/direct_file_store'

module Monitoring
  module Prometheus
    extend self

    def setup(options = {})
      @registry = options[:registry] || ::Prometheus::Client::Registry.new
      @metrics_prefix = options[:metrics_prefix] || "conjur_http_server"
      @metrics_dir_path = ENV['CONJUR_METRICS_DIR'] || '/tmp/prometheus'

      clear_data_store
      configure_data_store
      init_metrics
    end

    def registry
      @registry
    end

    def metrics_prefix
      @metrics_prefix
    end

    protected

    def clear_data_store
      Dir[File.join(@metrics_dir_path, '*.bin')].each do |file_path|
        File.unlink(file_path)
      end
    end

    def configure_data_store
      ::Prometheus::Client.config.data_store = ::Prometheus::Client::DataStores::DirectFileStore.new(
        dir: @metrics_dir_path
      )
    end

    def init_metrics
      # Test a random gauge metric
      gauge = registry.gauge(:test_gauge, docstring: '...', labels: [:test_label])
      gauge.set(1234.567, labels: { test_label: 'gauge metric test' })
    end

  end
end
