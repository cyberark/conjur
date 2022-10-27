require 'benchmark'
require_relative '../operations.rb'

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

      # Trace HTTP requests
      def trace(env)
        response = nil
        operation = find_operation(env['REQUEST_METHOD'], env['PATH_INFO'])
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration, operation)
        return response
      rescue => exception
        @pubsub.publish(
          "conjur.request_exception", 
          operation: operation,
          exception: exception.class.name,
          message: exception
        )
        raise
      end

      def record(env, code, duration, operation)
        @pubsub.publish(
          "conjur.request", 
          code: code,
          operation: operation,
          duration: duration
        )
      rescue
        # TODO: log unexpected exception during request recording
        nil
      end

      def find_operation(method, path)
        Monitoring::Metrics::OPERATIONS.each do |op|
          if op[:method] == method && op[:pattern].match?(path)
            return op[:operation]
          end
        end
        return "unknown"
      end
    end
  end
end
