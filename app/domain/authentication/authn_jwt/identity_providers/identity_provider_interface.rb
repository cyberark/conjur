module Authentication
  module AuthnJwt
    module IdentityProviders
      class IdentityProviderInterface
        def initialize(authentication_parameters); end
        def provide_jwt_identity; end
        def identity_available?; end
      end
    end
  end
end

