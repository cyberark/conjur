require 'prometheus/client'
require 'prometheus/client/data_stores/direct_file_store'
require_relative './metrics/resource_metric.rb'
require_relative './metrics/request_metric.rb'


module Monitoring
  class MetricsClient
      attr_reader :registry

      def initialize(options = {})
        clear_data_store
        configure_data_store

        @registry = options[:registry] || Prometheus::Client.registry
        @metrics_prefix = options[:metrics_prefix] || "conjur_http_server"
        @request_metric = Monitoring::Metrics::RequestMetric.new(
          metrics_prefix: @metrics_prefix,
          registry: @registry)
        @resource_metric = Monitoring::Metrics::ResourceMetric.new(
          registry: @registry
        )


        define_metrics
        init_metrics
      end

      protected

      # Add metrics to prometheus registry
      def define_metrics
        @request_metric.define_metrics
        @resource_metric.define_metrics
      end

      # Setup pub/sub events
      def init_metrics
        @request_metric.init_metrics
        @resource_metric.init_metrics
      end


      def configure_data_store
        Prometheus::Client.config.data_store = ::Prometheus::Client::DataStores::DirectFileStore.new(
          dir: ENV['CONJUR_METRICS_DIR'] || '/tmp/prometheus'
        )
      end

      def clear_data_store
        Dir[File.join(metrics_dir_path, '*.bin')].each do |file_path|
          File.unlink(file_path)
        end
      end

      def metrics_dir_path
        metrics_dir_path ||= ENV['CONJUR_METRICS_DIR'] || '/tmp/prometheus'
      end
  end
end