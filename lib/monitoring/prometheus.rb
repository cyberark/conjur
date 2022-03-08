require 'prometheus/client'
require 'prometheus/client/data_stores/direct_file_store'
require 'monitoring/pub_sub'

module Monitoring
  module Prometheus
    extend self

    def setup(options = {})
      @registry = options[:registry] || ::Prometheus::Client::Registry.new
      @metrics_prefix = options[:metrics_prefix] || "conjur_http_server"
      @metrics_dir_path = ENV['CONJUR_METRICS_DIR'] || '/tmp/prometheus'
      @pubsub = options[:pubsub] || PubSub.instance

      # Array of objects representing different metrics.
      # Each objects needs a .setup method, responsible for registering metrics
      # and subscribing to Pub/Sub events.
      @metrics = options[:metrics] || []

      clear_data_store
      configure_data_store
      setup_metrics
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

    def setup_metrics
      @metrics.each do |metric|
        metric.setup(@registry, @pubsub)
      end
    end

  end
end
