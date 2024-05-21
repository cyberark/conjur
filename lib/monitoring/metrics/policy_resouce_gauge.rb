module Monitoring
  module Metrics
    class PolicyResourceGauge
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_resource_count
        @docstring = 'Number of resources in Conjur database'
        # labels should be only in alphabetic order
        @labels = %i[environment kind tenant_id]
        @sub_event_name = 'conjur.policy_loaded'

        # Create/register the metric
        Metrics.create_metric(self, :gauge)

        # Run update to set the initial counts on startup
        update
      end

      def update(*_payload)
        metric = @registry.get(metric_name)
        Monitoring::QueryHelper.instance.policy_visible_resource_counts.each do |kind, value|
          # labels should be only in alphabetic order
          metric.set(value, labels: { environment: ENV['TENANT_ENV'], kind: kind, tenant_id: ENV['TENANT_ID'] })
        end
      end
    end
  end
end
