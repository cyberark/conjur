module Authentication
  module AuthnJwt
    module SigningKey
      class FetchSigningKeyInterface
        def initialize(authentication_parameters) ; end

        def create; end

        def jwks_uri_resource_exists; end
      end
    end
  end
end
