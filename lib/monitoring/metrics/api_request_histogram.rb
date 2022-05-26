module Monitoring
  module Metrics
    class ApiRequestHistogram
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name, :throttle

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_http_server_request_duration_seconds
        @docstring = 'The HTTP response duration of requests handled by Conjur.'
        @labels = %i[operation]
        @sub_event_name = 'conjur.request'

        # Create/register the metric
        Metrics.create_metric(self, :histogram)
      end

      def update(payload)
        metric = @registry.get(@metric_name)
        update_labels = {
          operation: payload[:operation]
        }
        metric.observe(payload[:duration], labels: update_labels)
      end
    end
  end
end
