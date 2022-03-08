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

        init_test_metric
      end

      def call(env)
        trace(env) { @app.call(env) }
      end

      protected

      def init_test_metric
        # Initializing a metric here as proof-of-concept.
        # The subscribed code block is given a payload that can include
        # general info about a given request - path, code, request duration.
        PubSub.unsubscribe("collector_test_metric")
        @registry.counter(
            :collector_test_metric,
            docstring: '...',
            labels: %i[code path]
        )
        PubSub.subscribe("collector_test_metric") do |payload|
          labels = {
            code: payload[:code],
            path: payload[:path],
          }
          @registry.get(:collector_test_metric).increment(labels: labels)
        end
      end

      def trace(env)
        response = nil
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration)
        return response
      rescue
        nil
      end

      def record(env, code, duration)
        # Publish global events based on code, path, and request duration.
        path = [env["SCRIPT_NAME"], env["PATH_INFO"]].join
        PubSub.publish(
          "collector_test_metric",
          code: code,
          path: path
        )
      rescue
        nil
      end

    end
  end
end
