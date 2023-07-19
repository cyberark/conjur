module Monitoring
  module Metrics
    class PolicyRoleGauge
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_role_count
        @docstring = 'Number of roles in Conjur database'
        @labels = %i[kind]
        @sub_event_name = 'conjur.policy_loaded'
        
        # Create/register the metric
        Metrics.create_metric(self, :gauge)

        # Run update to set the initial counts on startup
        update
      end

      def update(*payload)
        metric = registry.get(metric_name)
        Monitoring::QueryHelper.instance.policy_role_counts.each do |kind, value|
          metric.set(value, labels: { kind: kind }) unless kind == '!'
        end
      end
    end
  end
end
