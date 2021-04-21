require 'pry'

module Prometheus
  module Controller
    prometheus = Prometheus::Client.registry

    gauge = Prometheus::Client::Gauge.new(:test, docstring: 'Test gauge', labels: [:name, :env, :description])
    prometheus.register(gauge)

    # Register resource count guage
    resource_count_gauge = Prometheus::Client::Gauge.new(
      :conjur_resource_count,
      docstring: 'Number of resources in Conjur database',
      labels: [:kind]
    )
    prometheus.register(resource_count_gauge)

    def self.update_resource_count_metric
      resource_count_gauge = Prometheus::Client.registry.get(:conjur_resource_count)

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

    # Set initial resource counts
    update_resource_count_metric

    # Subscript to Conjur ActiveSupport events for metric updates
    ActiveSupport::Notifications.subscribe("policy_loaded.conjur") do
      # Update the resource counts after policy loads
      update_resource_count_metric
    end

    ActiveSupport::Notifications.subscribe("host_factory_host_created.conjur") do
      # Update the resource counts after host factories create a new host
      update_resource_count_metric
    end
  end
end
