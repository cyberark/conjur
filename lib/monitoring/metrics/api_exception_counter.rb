module Monitoring
  module Metrics
    class ApiExceptionCounter
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_request_exceptions_total
        @docstring = 'The total number of API exceptions raised by Conjur.'
        @labels = %i[environment exception operation tenant_id]
        @sub_event_name = 'conjur.request_exception'

        # Create/register the metric
        Metrics.create_metric(self, :counter)
      end

      def update(payload)
        metric = registry.get(metric_name)
        update_labels = {
          environment: ENV['TENANT_ENV'],
          exception: payload[:exception],
          operation: payload[:operation],
          tenant_id: ENV['TENANT_ID'],
        }
        metric.increment(labels: update_labels)
      end
    end
  end
end
