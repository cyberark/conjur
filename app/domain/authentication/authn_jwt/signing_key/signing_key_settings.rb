module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for JWKS fetching related settings of the authenticator
      class SigningKeySettings

        attr_reader :type, :uri, :cert_store, :signing_keys, :ca_cert

        def initialize(
          type:,
          uri: nil,
          cert_store: nil,
          signing_keys: nil,
          ca_cert: nil
        )
          @type = type
          @uri = uri
          @cert_store = cert_store
          @signing_keys = signing_keys
          @ca_cert = ca_cert
        end
      end
    end
  end
end
