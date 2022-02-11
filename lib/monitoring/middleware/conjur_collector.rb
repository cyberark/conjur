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
      attr_reader :app

      def initialize(app, options = {})
        @app = app
      end

      def call(env) # :nodoc:
        trace(env) { @app.call(env) }
      end

      protected

      # Trace HTTP requests
      def trace(env)
        response = nil
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration)
        return response
      rescue => exception
        print "Instrumenting exception:",exception,"\n"
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
    end
  end
end