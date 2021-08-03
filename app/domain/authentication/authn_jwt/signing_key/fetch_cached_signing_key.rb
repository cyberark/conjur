module Authentication
  module AuthnJwt
    module SigningKey
      # FetchCachedSigningKey is a wrapper of FetchSigningKeyInterface interface,
      # in order to be able to store the signing key in our cache mechanism. If signing_key_interface don't have
      # fetch_signing_key it is extreme case that error need to be raised so it can be investigated so reek will ignore
      # this.
      # :reek:InstanceVariableAssumption
      class FetchCachedSigningKey
        def initialize(logger: Rails.logger)
          @logger = logger
        end

        def call(signing_key_interface:)
          @signing_key_interface = signing_key_interface
          fetch_signing_key
        end

        private

        def fetch_signing_key
          @signing_key_interface.fetch_signing_key
        end
      end
    end
  end
end
