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
        @id_token_decoded = OpenIDConnect::ResponseObject::IdToken.decode(id_token_jwt, get_cert(provider_uri))

        attribs = @id_token_decoded.raw_attributes.to_hash

        # Verify id_token expiration. OpenIDConnect requires to verify few claims. mask required claims
        # such that effectively only expiration will be verified
        expected = {client_id: attribs[:aud] || attribs[:client_id], issuer: attribs[:iss], nonce: attribs[:nonce]}
        @id_token_decoded.verify!(expected)

        # return decoded attributes as hash
        attribs
      end

      private

      def get_cert(provider_uri)
        OpenIDConnect::Discovery::Provider::Config.discover!(provider_uri).jwks
      end
    end
  end
end
