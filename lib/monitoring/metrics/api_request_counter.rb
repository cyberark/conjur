module Monitoring
  module Metrics
    class ApiRequestCounter
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_requests_total
        @docstring = 'The total number of HTTP requests handled by Conjur.'
        @labels = %i[operation tenant_id]
        @sub_event_name = 'conjur.request'

        # Create/register the metric
        Metrics.create_metric(self, :counter)
      end

      def update(payload)
        if ((payload[:operation] == 'unknown') || (payload[:operation] == 'getMetrics'))
          return
        end
        metric = registry.get(metric_name)
        update_labels = {
          operation: payload[:operation],
          tenant_id: ENV['TENANT_ID']
        }
        metric.increment(labels: update_labels)
      end
    end
  end
end
