module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for parsing JWK set from public-keys configuration value
      class FetchPublicKeysSigningKey

        def initialize(
          public_keys:,
          logger: Rails.logger
        )
          @logger = logger
          @public_keys = public_keys
        end

        def call(*)
          @logger.info(LogMessages::Authentication::AuthnJwt::ParsingStaticSigningKeys.new)
          signing_keys = Authentication::AuthnJwt::SigningKey::PublicSigningKeys.new(JSON.parse(@public_keys))
          signing_keys.validate!
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsedStaticSigningKeys.new)
          { keys: JSON::JWK::Set.new(signing_keys.value) }
        end
      end
    end
  end
end
