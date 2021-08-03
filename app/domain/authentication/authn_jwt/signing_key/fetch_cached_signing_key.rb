module Authentication
  module AuthnJwt
    module SigningKey
      # FetchCachedSigningKey command class is a callable wrapper of FetchSigningKeyInterface interface,
      # in order to be able to store the signing key in our cache mechanism
      class FetchCachedSigningKey
        attr_accessor :authentication_parameters

        def initialize(
          logger: Rails.logger
        )
          @logger = logger
        end

        def call(signing_key_interface:)
          @signing_key_interface = signing_key_interface
          fetch_signing_key
        end

        def key
          @authentication_parameters.key
        end

        private

        # This shouldn't be memoized because this class is a dependency.
        # If its being memoized a JWKS provider can be returned when PROVIDER-URI in needed and PROVIDER-URI when
        # JWKS provider is needed
        def fetch_signing_key_interface
          @signing_key_interface = @create_signing_key_factory.call(
            authentication_parameters: @authentication_parameters
          )
        end

        def fetch_signing_key
          @signing_key_interface.fetch_signing_key
        end
      end
    end
  end
end
