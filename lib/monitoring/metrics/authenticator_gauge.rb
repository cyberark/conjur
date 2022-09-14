module Monitoring
  module Metrics
    class AuthenticatorGauge
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name, :throttle

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_server_authenticator
        @docstring = 'Number of authenticators enabled'
        @labels = [:type, :status]
        @sub_event_name = 'conjur.authenticator_count_update'
        @throttle = true
        
        # Create/register the metric
        Metrics.create_metric(self, :gauge)

        # Run update to set the initial counts on startup
        update
      end

      def update(*payload)
        metric = @registry.get(@metric_name)
        update_enabled_authenticators(metric)
        update_installed_authenticators(metric)
        update_configured_authenticators(metric)
      end

      def update_enabled_authenticators(metric)
        enabled_authenticators = Authentication::InstalledAuthenticators.enabled_authenticators
        enabled_authenticator_counts = get_authenticator_counts(enabled_authenticators)
        enabled_authenticator_counts.each do |type, count|
          metric.set(count, labels: { type: type, status: 'enabled'})
        end
      end

      def update_installed_authenticators(metric)
        installed_authenticators = Authentication::InstalledAuthenticators.authenticators(ENV).keys
        installed_authenticators.each do |type|
          metric.set(1, labels: { type: type, status: 'installed'})
        end
      end

      def update_configured_authenticators(metric)
        configured_authenticators =  Authentication::InstalledAuthenticators.configured_authenticators
        configured_authenticator_counts = get_authenticator_counts(configured_authenticators)
        configured_authenticator_counts.each do |type, count|
          metric.set(count, labels: { type: type, status: 'configured'})
        end
      end

      def get_authenticator_counts(authenticators)
        authenticator_counts = {}
        authenticators.each do |authenticator|
          type = authenticator.split('/')[0]
          authenticator_counts[type] ? authenticator_counts[type] += 1 : authenticator_counts[type] = 1
        end
        return authenticator_counts
      end
    end
  end
end
