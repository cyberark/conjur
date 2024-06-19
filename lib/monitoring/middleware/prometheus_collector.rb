require 'benchmark'
require_relative '../operations'

module Monitoring
  module Middleware
    class PrometheusCollector
      attr_reader :app

      def initialize(app, options = {})
        @app = app
        @pubsub = options[:pubsub]
        @lazy_init = options[:lazy_init]
      end

      def call(env) # :nodoc:
        unless @initialized
          @initialized = true
          @lazy_init.call
        end
        trace(env) { @app.call(env) }
      end

      protected

      def filter_out?(path_info)
        return path_info.start_with?("/secrets/conjur/variable/replicator") ||
          path_info.start_with?("/secrets/conjur/variable/conjur") ||
          path_info.start_with?("/authn-jwt/internal-")
      end

      # Trace HTTP requests
      def trace(env)
        response = nil
        path_info = env['PATH_INFO']
        operation = find_operation(env['REQUEST_METHOD'], env['PATH_INFO'])
        duration = Benchmark.realtime { response = yield }

        unless filter_out?(path_info)
          record(env, response.first.to_s, duration, operation)
        end
        response
      rescue => e
        @pubsub.publish(
          "conjur.request_exception",
          operation: operation,
          exception: e.class.name,
          message: e
        )
        raise
      end

      def record(_env, code, duration, operation)
        @pubsub.publish(
          "conjur.request",
          code: code,
          operation: operation,
          duration: duration
        )
      rescue => e
        Rails.logger.debug(LogMessages::Monitoring::ExceptionDuringRequestRecording.new(e.inspect))
      end

      def find_operation(method, path)
        Monitoring::Metrics::OPERATIONS.each do |op|
          if op[:method] == method && op[:pattern].match?(path)
            return op[:operation]
          end
        end
        "unknown"
      end
    end
  end
end
