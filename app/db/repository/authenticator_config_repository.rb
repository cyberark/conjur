# frozen_string_literal: true

module DB
  module Repository
    class AuthenticatorConfigRepository

      AUTHN_RESOURCE_PREFIX = "conjur/authn-"

      def configured_authenticators
        identifier = Sequel.function(:identifier, :resource_id)
        kind = Sequel.function(:kind, :resource_id)

        Resource
          .where(identifier.like("#{AUTHN_RESOURCE_PREFIX}%"))
          .where(kind => "webservice")
          .select_map(identifier)
          .map { |id| id[%r{^conjur/(authn(?:-[^/]+)?(?:/[^/]+)?)$}, 1] } # filter out nested status webservice
          .compact
          .push(::Authentication::Common.default_authenticator_name)
      end

      def enabled_authenticators
        # We want to allow authn when there is no authenticator configured
        # so that we can still authenticate to Conjur, in case user has
        # taken explicit decision on enablement we should respect it
        authenticators = Rails.application.config.conjur_config.authenticators.presence || native_authenticators
        (authenticators | db_enabled_authenticators)
      end

      def enabled_authenticators_str
        enabled_authenticators.join(',')
      end

      def native_authenticators
        %w[authn]
      end

      private

      def db_enabled_authenticators
        AuthenticatorConfig.where(enabled: true)
          .map { |row| row.resource_id.split('/').drop(1).join('/') }
      end
    end
  end
end
