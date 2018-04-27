module Authentication
  class InstalledAuthenticators

    def self.new(env, authentication_module: ::Authentication)
      ::Util::Submodules.of(authentication_module)
        .flat_map { |mod| ::Util::Submodules.of(mod) }
        .select { |cls| valid?(cls) }
        .map { |cls| [url_for(cls), authenticator_instance(cls, env)] }
        .to_h
    end

    private

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

  end
end
