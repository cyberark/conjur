module Authentication
  class InstalledAuthenticators

    def self.new(env, authentication_module: ::Authentication)
      ::Util::Submodules.of(authentication_module)
        .flat_map { |mod| ::Util::Submodules.of(mod) }
        .select { |cls| ::Authentication::AuthenticatorClass.valid?(cls) }
        .map { |cls| [url_for(cls), authenticator_instance(cls, env)] }
        .to_h
    end

    private

    def self.authenticator_instance(cls, env)
      pass_env = ::Authentication::AuthenticatorClass.requires_env_arg?(cls)
      pass_env ? cls.new(env: env) : cls.new
    end

    def self.url_for(authenticator)
      ::Authentication::AuthenticatorClass.new(authenticator).url_name
    end

  end
end
