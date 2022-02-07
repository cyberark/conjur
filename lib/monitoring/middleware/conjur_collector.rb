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
    class ConjurCollector
      attr_reader :app, :registry

      def initialize(app, options = {})
        @app = app
        @registry = options[:registry] || Client.registry
        @metrics_prefix = options[:metrics_prefix] || 'conjur_http_server'
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
        ActiveSupport::Notifications.instrument("request_exception.conjur", exception: exception)
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
      rescue
        Rails.logger.error(e)
        nil
      end
    end
  end
end