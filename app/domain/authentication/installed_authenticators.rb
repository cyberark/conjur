# frozen_string_literal: true

module Authentication
  class InstalledAuthenticators

    def self.authenticators(env, authentication_module: ::Authentication)
      loaded_authenticators(authentication_module)
        .select { |cls| valid?(cls) }
        .map { |cls| [url_for(cls), authenticator_instance(cls, env)] }
        .to_h
    end

    def self.login_authenticators(env, authentication_module: ::Authentication)
      loaded_authenticators(authentication_module)
        .select { |cls| provides_login?(cls) }
        .map { |cls| [url_for(cls), authenticator_instance(cls, env)] }
        .to_h
    end

    private

    def self.loaded_authenticators(authentication_module)
      ::Util::Submodules.of(authentication_module)
        .flat_map { |mod| ::Util::Submodules.of(mod) }
    end

    def self.authenticator_instance(cls, env)
      pass_env = ::Authentication::AuthenticatorClass.new(cls).requires_env_arg?
      pass_env ? cls.new(env: env) : cls.new
    end

    def self.url_for(authenticator)
      ::Authentication::AuthenticatorClass.new(authenticator).url_name
    end

    def self.valid?(cls)
      ::Authentication::AuthenticatorClass::Validation.new(cls).valid?
    end

    def self.provides_login?(cls)
      validation = ::Authentication::AuthenticatorClass::Validation.new(cls)
      validation.valid? && validation.provides_login?
    end
  end
end
