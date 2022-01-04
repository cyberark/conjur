module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching JWK Set from JWKS-uri
      class SigningKeySettings
        def initialize(signing_key_uri:,
                       signing_key_type:)
          @signing_key_uri = signing_key_uri
          @signing_key_type = signing_key_type
        end
      end
    end
  end
end