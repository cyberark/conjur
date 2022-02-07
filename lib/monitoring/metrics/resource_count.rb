require 'prometheus/client'

module Monitoring
  module Metrics
    class ResourceCount
      def define_metric(registry)
        registry.register(resource_count_gauge)
      end

      def init_metric(registry)
        # Set initial count metrics
        update_resource_count_metric(registry)

        # Subscribe to Conjur ActiveSupport events for metric updates
        ActiveSupport::Notifications.subscribe("policy_loaded.conjur") do
          # Update the resource counts after policy loads
          update_resource_count_metric(registry)
        end

        ActiveSupport::Notifications.subscribe("host_factory_host_created.conjur") do
          # Update the resource counts after host factories create a new host
          update_resource_count_metric(registry)
        end
      end

      private

      def resource_count_gauge
        ::Prometheus::Client::Gauge.new(
          :conjur_resource_count,
          docstring: 'Number of resources in Conjur database',
          labels: [:kind, :component],
          preset_labels: { component: "conjur" },
          store_settings: {
            aggregation: :most_recent
          }
        )
      end

      def update_resource_count_metric(registry)
        resource_count_gauge = registry.get(:conjur_resource_count)

        kind = ::Sequel.function(:kind, :resource_id)
        Resource.group_and_count(kind).each do |record|
          resource_count_gauge.set(
            record[:count],
            labels: {
              kind: record[:kind]
            }
          )
        end
      end
    end
  end
end