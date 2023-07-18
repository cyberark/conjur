module Monitoring
  module Metrics
    class AuthenticatorGauge
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_server_authenticator
        @docstring = 'Number of authenticators enabled'
        @labels = [:type, :status]
        @sub_event_name = 'conjur.policy_loaded'
        
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
        authenticators.each_with_object(Hash.new(0)) do |authenticator, rtn|
          type = authenticator.split('/').first
          rtn[type] += 1
        end
      end
    end
  end
end
