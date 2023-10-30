# frozen_string_literal: true

module Authentication
  class InstalledAuthenticators

    AUTHN_RESOURCE_PREFIX = "conjur/authn-"

    class << self
      def authenticators(env, authentication_module: ::Authentication)
        loaded_authenticators(authentication_module)
          .select { |cls| valid?(cls) }
          .map { |cls| [url_for(cls), authenticator_instance(cls, env)] }
          .to_h
      end

      def login_authenticators(env, authentication_module: ::Authentication)
        loaded_authenticators(authentication_module)
          .select { |cls| provides_login?(cls) }
          .map { |cls| [url_for(cls), authenticator_instance(cls, env)] }
          .to_h
      end

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
        # Enabling via environment overrides enabling via CLI
        authenticators = 
          Rails.application.config.conjur_config.authenticators
        authenticators.empty? ? db_enabled_authenticators : authenticators
      end

      def enabled_authenticators_str
        enabled_authenticators.join(',')
      end

      def native_authenticators
        %w[authn]
      end

      private

      def db_enabled_authenticators
        # Always include 'authn' when enabling authenticators via CLI so that it
        # doesn't get disabled when another authenticator is enabled
        AuthenticatorConfig.where(enabled: true)
          .map { |row| row.resource_id.split('/').drop(1).join('/') }
          .append("authn")
      end

      def loaded_authenticators(authentication_module)
        ::Util::Submodules.of(authentication_module)
          .flat_map { |mod| ::Util::Submodules.of(mod) }
      end

      def authenticator_instance(cls, env)
        pass_env = ::Authentication::AuthenticatorClass.new(cls).requires_env_arg?
        pass_env ? cls.new(env: env) : cls.new
      end

      def url_for(authenticator)
        ::Authentication::AuthenticatorClass.new(authenticator).url_name
      end

      def valid?(cls)
        ::Authentication::AuthenticatorClass::Validation.new(cls).valid?
      end

      def provides_login?(cls)
        validation = ::Authentication::AuthenticatorClass::Validation.new(cls)
        validation.valid? && validation.provides_login?
      end
    end
  end
end
