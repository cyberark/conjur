# encoding: UTF-8

require 'benchmark'
require 'prometheus/client'
require 'prometheus/client/data_stores/direct_file_store'
require ::File.expand_path('../../metrics/request_metric.rb', __FILE__)
require ::File.expand_path('../../metrics/resource_metric.rb', __FILE__)

module Prometheus
  module Middleware
    # Collector is a Rack middleware that provides a sample implementation of a
    # HTTP tracer.
    #
    # By default metrics are registered on the global registry. Set the
    # `:registry` option to use a custom registry.
    class ConjurCollector
      attr_reader :app, :registry

      def initialize(app, options = {})
        clear_data_store
        configure_data_store

        @app = app
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

      def call(env) # :nodoc:
        trace(env) { @app.call(env) }
      end

      protected

      # Add metrics to prometheus registry
      def define_metrics
        @request_metric.define_metrics
        @resource_metric.define_metrics
      end

      def init_metrics
        @request_metric.init_metrics
        @resource_metric.init_metrics
      end

      def trace(env)
        response = nil
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration)
        return response
      rescue => exception
        puts "Trace exception:",exception
        # exceptions = @registry.get(:"#{@metrics_prefix}_exceptions_total")
        # exceptions.increment(labels: { exception: exception.class.name })

        ActiveSupport::Notifications.instrument("request_exception.conjur", 
          exception: exception
        )

        raise
      end

      def record(env, code, duration)
        path = [env["SCRIPT_NAME"], env['PATH_INFO']].join
        ActiveSupport::Notifications.instrument("request.conjur", 
          code: code,
          method: env['REQUEST_METHOD'],
          path: strip_ids_from_path(path),
          duration: duration
        )
      rescue
        # TODO: log unexpected exception during request recording
        nil
      end

      def strip_ids_from_path(path)
        path.gsub(%r{/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(?=/|$)}, '/:uuid\\1').gsub(%r{/\d+(?=/|$)}, '/:id\\1')
      end

      def configure_data_store
        ::Prometheus::Client.config.data_store = ::Prometheus::Client::DataStores::DirectFileStore.new(
          dir: ENV['CONJUR_METRICS_DIR'] || '/tmp/prometheus'
        )
      end

      def clear_data_store
        Dir[File.join(metrics_dir_path, '*.bin')].each do |file_path|
          File.unlink(file_path)
        end
      end

      def metrics_dir_path
        @metrics_dir_path ||= ENV['CONJUR_METRICS_DIR'] || '/tmp/prometheus'
      end
    end
  end
end