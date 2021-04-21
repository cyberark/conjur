require 'benchmark'
require 'prometheus/client'

require_relative './operations.rb'

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
    class CustomCollector
      attr_reader :app, :registry

      def initialize(app, options = {})
        @app = app
        @registry = options[:registry] || Client.registry
        @metrics_prefix = options[:metrics_prefix] || 'http_server'

        init_request_metrics
        init_exception_metrics
      end

      def call(env) # :nodoc:
        trace(env) { @app.call(env) }
      end

      protected

      def init_request_metrics
        @requests = @registry.counter(
          :"#{@metrics_prefix}_requests_total",
          docstring:
            'The total number of HTTP requests handled by the Rack application.',
          labels: %i[code operation]
        )
        @durations = @registry.histogram(
          :"#{@metrics_prefix}_request_duration_seconds",
          docstring: 'The HTTP response duration of the Rack application.',
          labels: %i[operation]
        )
      end

      def init_exception_metrics
        @exceptions = @registry.counter(
          :"#{@metrics_prefix}_exceptions_total",
          docstring: 'The total number of exceptions raised by the Rack application.',
          labels: [:exception]
        )
      end

      def trace(env)
        response = nil
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration)
        return response
      rescue => exception
        @exceptions.increment(labels: { exception: exception.class.name })
        raise
      end

      def find_operation(method, path)
        OPERATIONS.each do |op|
          if op[:method] == method && op[:pattern].match?(path)
            return op[:operation]
          end
        end

        return "unknown"
      end

      def record(env, code, duration)
        path = [env["SCRIPT_NAME"], env['PATH_INFO']].join

        operation = find_operation(env['REQUEST_METHOD'], path)

        counter_labels = {
          code: code,
          operation: operation,
        }

        duration_labels = {
          operation: operation,
        }

        @requests.increment(labels: counter_labels)
        @durations.observe(duration, labels: duration_labels)
      rescue StandardError => e
        Rails.logger.error(e)

        nil
      end
    end
  end
end
