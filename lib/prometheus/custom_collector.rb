require 'benchmark'
require 'prometheus/client'

module Prometheus
  module Middleware
    # Collector is a Rack middleware that provides a sample implementation of a
    # HTTP tracer.
    #
    class CustomCollector
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env) # :nodoc:
        trace(env) { @app.call(env) }
      end

      protected

      def trace(env)
        response = nil
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration)
        return response
      rescue => exception
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
          path: path,
          duration: duration
        )
      rescue StandardError => e
        Rails.logger.error(e)

        nil
      end
    end
  end
end
