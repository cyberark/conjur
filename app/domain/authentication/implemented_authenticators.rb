# frozen_string_literal: true

module Authentication
  class ImplementedAuthenticators

    class << self
      def authenticators(env, authentication_module: ::Authentication)
        v2_authenticators = Authentication::Util::V2::AuthenticatorLoader.all

        v1_authenticators = loaded_authenticators(authentication_module)
          .select { |cls| valid?(cls) }
          .map { |cls| [url_for(cls), authenticator_instance(cls, env)] }
          .to_h

        # Merge the V1 and V2 authenticators prioritizing V1
        v2_authenticators.merge(v1_authenticators)
      end

      def login_authenticators(env, authentication_module: ::Authentication)
        loaded_authenticators(authentication_module)
          .select { |cls| provides_login?(cls) }
          .map { |cls| [url_for(cls), authenticator_instance(cls, env)] }
          .to_h
      end

      private

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
