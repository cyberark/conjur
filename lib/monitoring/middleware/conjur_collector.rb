# encoding: UTF-8

require 'benchmark'
require 'prometheus/client'
require 'prometheus/client/data_stores/direct_file_store'
#require_relative '../metrics/operations.rb'
#require ::File.expand_path('../../metrics/operations.rb', __FILE__)

module Prometheus
  module Middleware
    # Collector is a Rack middleware that provides a sample implementation of a
    # HTTP tracer.
    #
    # By default metrics are registered on the global registry. Set the
    # `:registry` option to use a custom registry.
    #
    # By default metrics all have the prefix "http_server". Set
    # `:metrics_prefix` to something else if you like.
    #
    # The request counter metric is broken down by code, method and path.
    # The request duration metric is broken down by method and path.
    class ConjurCollector
      attr_reader :app, :registry

      def initialize(app, options = {})
        clear_data_store
        configure_data_store

        @app = app
        @registry = options[:registry] || Client.registry
        @metrics_prefix = options[:metrics_prefix] || 'conjur_http_server'

        define_metrics
        init_metrics
      end

      def call(env) # :nodoc:
        trace(env) { @app.call(env) }
      end

      protected

      # Add metrics to prometheus registry
      def define_metrics
        # @requests = @registry.counter(
        #   :"#{@metrics_prefix}_requests_total",
        #   docstring:
        #     'The total number of HTTP requests handled by the Rack application.',
        #   labels: %i[code method path]
        # )
        # @durations = @registry.histogram(
        #   :"#{@metrics_prefix}_request_duration_seconds",
        #   docstring: 'The HTTP response duration of the Rack application.',
        #   labels: %i[method path]
        # )
        # @exceptions = @registry.counter(
        #   :"#{@metrics_prefix}_exceptions_total",
        #   docstring: 'The total number of exceptions raised by the Rack application.',
        #   labels: [:exception]
        # )

        @registry.register(request_count)
        @registry.register(request_histogram)
        @registry.register(exception_count)
        @registry.register(resource_count_gauge)
      end

      def request_count
        Prometheus::Client::Counter.new(
          :"#{@metrics_prefix}_requests_total",
          docstring: 'The total number of HTTP requests handled by the Rack application.',
          labels: %i[code method path]
        )
      end

      def request_histogram
        Prometheus::Client::Histogram.new(
          :"#{@metrics_prefix}_request_duration_seconds",
          docstring: 'The HTTP response duration of the Rack application.',
          labels: %i[method path]
        )
      end

      def exception_count
        Prometheus::Client::Counter.new(
          :"#{@metrics_prefix}_exceptions_total",
          docstring: 'The total number of exceptions raised by the Rack application.',
            labels: [:exception]
        )
      end

      # Subscribe to events for metrics collection
      def init_metrics
        puts "Initializing"
        ActiveSupport::Notifications.subscribe("request_exception.conjur") do |_, _, _, _, payload|
          puts "Incrementing exception", payload[:exception]
          exceptions = @registry.get(:"#{@metrics_prefix}_exceptions_total")
          exceptions.increment(labels: { exception: payload[:exception].class.name })
        end

        ActiveSupport::Notifications.subscribe("request.conjur") do |_, _, _, _, payload|
          method = payload[:method]
          code = payload[:code]
          path = payload[:path]
          duration = payload[:duration]


          counter_labels = {
            code:   code,
            method: method,
            path:   path,
          }
  
          duration_labels = {
            method: method,
            path:   path,
          }

          puts "Incrementing requests"
          @registry.get(:"#{@metrics_prefix}_requests_total").increment(labels: counter_labels)
          puts "Incrementing durations"
          @registry.get(:"#{@metrics_prefix}_request_duration_seconds").observe(duration, labels: duration_labels)
          puts "Incremented!"
        end

        # Set initial count metrics
        puts "Setup endpoint subscribers"
        update_resource_count_metric(@registry)

        # Subscribe to Conjur ActiveSupport events for metric updates
        ActiveSupport::Notifications.subscribe("policy_loaded.conjur") do
          # Update the resource counts after policy loads
          update_resource_count_metric(@registry)
        end

        ActiveSupport::Notifications.subscribe("host_factory_host_created.conjur") do
          # Update the resource counts after host factories create a new host
          update_resource_count_metric(@registry)
        end

        puts "Setup resource subscribers"

        
      end

      def trace(env)
        response = nil
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration)
        return response
      rescue => exception
        exceptions = @registry.get(:"#{@metrics_prefix}_exceptions_total")
        exceptions.increment(labels: { exception: exception.class.name })

        # puts "Trace exception:",exception
        # ActiveSupport::Notifications.instrument("request_exception.conjur", 
        #   exception: exception
        # )
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

      def resource_count_gauge
        ::Prometheus::Client::Gauge.new(
          :conjur_resource_count,
          docstring: 'Number of resources in Conjur database',
          labels: [:kind, :component],
          preset_labels: { component: "conjur" },
          store_settings: {
            aggregation: :most_recent
          }
        )
      end

      def update_resource_count_metric(registry)
        resource_count_gauge = registry.get(:conjur_resource_count)

        kind = ::Sequel.function(:kind, :resource_id)
        Resource.group_and_count(kind).each do |record|
          resource_count_gauge.set(
            record[:count],
            labels: {
              kind: record[:kind]
            }
          )
        end
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