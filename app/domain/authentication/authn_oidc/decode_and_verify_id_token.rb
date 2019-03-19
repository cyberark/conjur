require 'uri'
require 'openid_connect'

module Authentication
  module AuthnOidc
    DecodeAndVerifyIdToken = CommandClass.new(
      dependencies: {
      },
      inputs: %i(provider_uri id_token_jwt)
    ) do

      def call
        # decode id token and Validate signing.
        @id_token_decoded = OpenIDConnect::ResponseObject::IdToken.decode(
          @id_token_jwt,
          get_cert(@provider_uri)
        )

        attributes = @id_token_decoded.raw_attributes

        # Verify id_token expiration. OpenIDConnect requires to verify few claims.
        # Mask required claims such that effectively only expiration will be verified
        expected = { client_id: attributes[:aud] || attributes[:client_id],
                     issuer: attributes[:iss],
                     nonce: attributes[:nonce] }
        @id_token_decoded.verify!(expected)

        # return decoded attributes as hash
        attributes
      end

      private

      def get_cert(provider_uri)
        OpenIDConnect::Discovery::Provider::Config.discover!(provider_uri).jwks
      end
    end
  end
end
