module Authentication
  module AuthnJwt
    module IdentityProviders
      # Interface for identity providers to implement in a way they work well with create_identity_provider factory
      class IdentityProviderInterface
        def initialize(authentication_parameters:); end

        def jwt_identity; end

        def identity_available?; end
      end
    end
  end
end
