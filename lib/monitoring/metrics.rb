require 'prometheus/client'
require 'prometheus/client/data_stores/direct_file_store'
require_relative './metrics/resource_count.rb'
require_relative './metrics/request.rb'


module Monitoring
  module Metrics
    extend self

      def setup(options= {})
        clear_data_store
        @registry = options[:registry] || Prometheus::Client::Registry.new
        @metrics_prefix = options[:metrics_prefix] || "conjur_http_server"
        configure_data_store
        define_metrics
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
        Dir[File.join(metrics_dir_path, '*.bin')].each do |file_path|
          File.unlink(file_path)
        end
      end

      def configure_data_store
        Prometheus::Client.config.data_store = ::Prometheus::Client::DataStores::DirectFileStore.new(
          dir: ENV['CONJUR_METRICS_DIR'] || '/tmp/prometheus'
        )
      end

      # Setup pub/sub events
      def init_metrics
        request.init_metrics
        resource_count.init_metrics
      end

      # Add metrics to prometheus registry
      def define_metrics
        request.define_metrics
        resource_count.define_metrics
      end

      def metrics_dir_path
        metrics_dir_path ||= ENV['CONJUR_METRICS_DIR'] || '/tmp/prometheus'
      end

      def request
        Monitoring::Metrics::Request.new(
          metrics_prefix: metrics_prefix,
          registry: @registry)
      end

      def resource_count
        Monitoring::Metrics::ResourceCount.new(
          registry: @registry
        )
      end
  end
end