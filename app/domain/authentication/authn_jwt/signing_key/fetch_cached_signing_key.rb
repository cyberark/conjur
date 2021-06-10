module Authentication
  module AuthnJwt
    module SigningKey
      # FetchCachedSigningKey command class is a callable wrapper of FetchSigningKeyInterface interface,
      # in order to be able to store the signing key in our cache mechanism
      FetchCachedSigningKey ||= CommandClass.new(
        dependencies: {
          fetch_signing_key_interface: ::Authentication::AuthnJwt::SigningKey::FetchSigningKeyInterface
        },
        inputs: %i[]
      ) do

        def call
          fetch_signing_key
        end

        private

        def fetch_signing_key
          @fetch_signing_key_interface.fetch_signing_key
        end
      end
    end
  end
end
