require 'prometheus/client'

module Monitoring
  module Metrics
    # By default metrics all have the prefix "conjur_http_server". Set
    # `:metrics_prefix` to something else if you like.
    #
    # The request counter metric is broken down by code, method and path.
    # The request duration metric is broken down by method and path.
    class Request
      def initialize(options = {})
        @metrics_prefix = options[:metrics_prefix] || 'conjur_http_server'
        @registry = options[:registry] || Prometheus::Client.registry
      end

      def define_metrics
        @registry.register(request_count)
        @registry.register(request_histogram)
        @registry.register(exception_count)
      end

      def init_metrics
        # Have to reset subscribers otherwise rspec was capturing duplicate events
        # due to init_metrics being called between tests
        reset_subscribers

        ActiveSupport::Notifications.subscribe("request_exception.conjur") do |_, _, _, _, payload|
          exception_labels = { 
            exception: payload[:exception].class.name 
          }

          @registry.get(:"#{@metrics_prefix}_exceptions_total").increment(labels: exception_labels)
        end

        ActiveSupport::Notifications.subscribe("request.conjur") do |_, _, _, _, payload|
          method = payload[:method]
          code = payload[:code]
          path = payload[:path]
          duration = payload[:duration]

          counter_labels = {
            code:   code,
            method: method,
            path:   path,
          }
  
          duration_labels = {
            method: method,
            path:   path,
          }

          @registry.get(:"#{@metrics_prefix}_requests_total").increment(labels: counter_labels)
          @registry.get(:"#{@metrics_prefix}_request_duration_seconds").observe(duration, labels: duration_labels)
        end
      end

      def request_count
        Prometheus::Client::Counter.new(
          :"#{@metrics_prefix}_requests_total",
          docstring: 'The total number of HTTP requests handled by the Rack application.',
          labels: %i[code method path]
        )
      end

      def request_histogram
        Prometheus::Client::Histogram.new(
          :"#{@metrics_prefix}_request_duration_seconds",
          docstring: 'The HTTP response duration of the Rack application.',
          labels: %i[method path]
        )
      end

      def exception_count
        Prometheus::Client::Counter.new(
          :"#{@metrics_prefix}_exceptions_total",
          docstring: 'The total number of exceptions raised by the Rack application.',
            labels: [:exception]
        )
      end

      def reset_subscribers
        ActiveSupport::Notifications.unsubscribe("request_exception.conjur")
        ActiveSupport::Notifications.unsubscribe("request.conjur")
      end
    end
  end
end