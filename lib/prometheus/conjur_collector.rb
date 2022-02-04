# encoding: UTF-8

require 'benchmark'
require 'prometheus/client'

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
        @app = app
        @registry = options[:registry] || Client.registry
        @metrics_prefix = options[:metrics_prefix] || 'conjur_http_server'

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
          labels: %i[code method path]
        )
        @durations = @registry.histogram(
          :"#{@metrics_prefix}_request_duration_seconds",
          docstring: 'The HTTP response duration of the Rack application.',
          labels: %i[method path]
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

      def record(env, code, duration)
        path = [env["SCRIPT_NAME"], env['PATH_INFO']].join

        counter_labels = {
          code:   code,
          method: env['REQUEST_METHOD'].downcase,
          path:   path,
        }

        duration_labels = {
          method: env['REQUEST_METHOD'].downcase,
          path:   path,
        }

        @requests.increment(labels: counter_labels)
        @durations.observe(duration, labels: duration_labels)
      rescue
        # TODO: log unexpected exception during request recording
        nil
      end

    end
  end
end