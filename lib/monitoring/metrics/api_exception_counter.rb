module Monitoring
  module Metrics
    class ApiExceptionCounter
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_http_server_request_exceptions_total
        @docstring = 'The total number of API exceptions raised by Conjur.'
        @labels = %i[operation exception message]
        @sub_event_name = 'conjur.request_exception'

        # Create/register the metric
        Metrics.create_metric(self, :counter)
      end

      def update(payload)
        metric = registry.get(metric_name)
        update_labels = {
          operation: payload[:operation],
          exception: payload[:exception],
          message: payload[:message]
        }
        metric.increment(labels: update_labels)
      end
    end
  end
end
