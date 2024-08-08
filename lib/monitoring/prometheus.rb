require 'prometheus/client'
require 'prometheus/client/data_stores/direct_file_store'
require_relative './pub_sub'

module Monitoring
  module Prometheus
    extend self

    attr_reader :registry, :metrics

    def setup(options = {})
      unsetup_metrics if @metrics

      @registry = options[:registry] || ::Prometheus::Client::Registry.new
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

    def unsetup_metrics
      if @pubsub.is_a?(PubSub)
        @metrics.each do |metric|
          @pubsub.unsubscribe(metric.sub_event_name)
        end
      end
    end

  end
end
