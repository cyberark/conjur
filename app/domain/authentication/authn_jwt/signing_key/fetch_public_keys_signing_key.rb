module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for parsing JWK set from public-keys configuration value
      class FetchPublicKeysSigningKey

        def initialize(
          signing_keys:,
          logger: Rails.logger
        )
          @logger = logger
          @signing_keys = signing_keys
        end

        def call(*)
          @logger.info(LogMessages::Authentication::AuthnJwt::ParsingStaticSigningKeys.new)
          public_signing_keys = Authentication::AuthnJwt::SigningKey::PublicSigningKeys.new(JSON.parse(@signing_keys))
          public_signing_keys.validate!
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsedStaticSigningKeys.new)
          { keys: JSON::JWK::Set.new(public_signing_keys.value) }
        end
      end
    end
  end
end
