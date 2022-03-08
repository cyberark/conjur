require 'benchmark'
require ::File.expand_path('../../pub_sub.rb', __FILE__)

module Monitoring
  module Middleware
    class ConjurCollector
      attr_reader :app, :registry, :pubsub

      def initialize(app, options = {})
        @app = app
        @registry = options[:registry]
        @pubsub = options[:pubsub]

        init_metrics
      end

      def call(env)
        trace(env) { @app.call(env) }
      end

      protected

      def init_metrics
        requests = @registry.counter(
          :"conjur_http_server_requests_total",
          docstring: 'The total number of HTTP requests handled by the Rack application',
          labels: %i[code method path]
        )
        PubSub.subscribe("conjur_http_server_requests_total") do
          guage = @registry.gauge(
            :duration_test,
            docstring: '...',
            labels: [:test_label]
          )
          gauge.set(21212, labels: { test_label: 'total metric test' })
          
          labels = {
            code: payload[:code],
            method: payload[:method],
            path: payload[:path]
          }
          requests.increment(labels: labels)
        end

        durations = @registry.histogram(
          :"conjur_http_server_request_duration_seconds",
          docstring: 'The HTTP response duration of the Rack application',
          labels: %i[path method]
        )
        PubSub.subscribe("conjur_http_server_request_duration_seconds") do
          guage = @registry.gauge(
            :duration_test,
            docstring: '...',
            labels: [:test_label]
          )
          gauge.set(10101, labels: { test_label: 'duration metric test' })

          labels = {
            method: payload[:method],
            path: payload[:path]
          }
          durations.observe(payload[:duration], labels: labels)
        end
      end

      def trace(env)
        response = nil
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration)
        return response
      rescue => exception
        PubSub.publish('conjur_request_exception', exception: exception)
        raise
      end

      def record(env, code, duration)
        path = [env["SCRIPT_NAME"], env["PATH_INFO"]].join

        PubSub.publish(
          "conjur_http_server_requests_total",
          code: code,
          path: path,
          method: env['REQUEST_METHOD']
        )
        PubSub.publish(
          "conjur_http_server_request_duration_seconds",
          duration: duration,
          path: path,
          method: env['REQUEST_METHOD']
        )
      rescue
        nil
      end

    end
  end
end