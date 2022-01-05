require_relative './operations.rb'
require 'prometheus/client'

module Monitoring
  module Metrics
    # By default metrics all have the prefix "http_server". Set
    # `:metrics_prefix` to something else if you like.
    #
    # The request counter metric is broken down by code, method and path.
    # The request duration metric is broken down by method and path.
    class Endpoints
      def initialize(options = {})
        @metrics_prefix = options[:metrics_prefix] || 'http_server'
      end

      def define_metrics(registry)
        @requests = registry.counter(
          :"#{@metrics_prefix}_requests_total",
          docstring:
            'The total number of HTTP requests handled by the Rack application.',
          labels: %i[code operation]
        )
        @durations = registry.histogram(
          :"#{@metrics_prefix}_request_duration_seconds",
          docstring: 'The HTTP response duration of the Rack application.',
          labels: %i[operation]
        )
        @exceptions = registry.counter(
          :"#{@metrics_prefix}_exceptions_total",
          docstring: 'The total number of exceptions raised by the Rack application.',
          labels: [:exception]
        )
      end

      def init_metrics(registry)
        ActiveSupport::Notifications.subscribe("request_exception.conjur") do |_, _, _, _, payload|
          @exceptions.increment(labels: { exception: exception.class.name })
        end

        ActiveSupport::Notifications.subscribe("request.conjur") do |_, _, _, _, payload|
          method = payload[:method]
          code = payload[:code]
          path = payload[:path]
          duration = payload[:duration]
  
          operation = find_operation(method, path)

          counter_labels = {
            code: code,
            operation: operation,
          }
  
          duration_labels = {
            operation: operation,
          }
  
          @requests.increment(labels: counter_labels)
          @durations.observe(duration, labels: duration_labels)
        end
      end

      private

      def find_operation(method, path)
        OPERATIONS.each do |op|
          if op[:method] == method && op[:pattern].match?(path)
            return op[:operation]
          end
        end

        return "unknown (#{method} #{path})"
      end
    end
  end
end
