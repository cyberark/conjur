module Authentication
  module AuthnJwt
    # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
    class ConfigurationJWTGenericVendor < ConfigurationInterface

      def initialize
        @validate_and_decode_token_class = Authentication::AuthnJwt::ValidateAndDecodeToken

        @extract_token_from_credentials = Authentication::AuthnJwt::ExtractTokenFromCredentials.new
        @restriction_validator = Authentication::AuthnJwt::ValidateRestrictionsOneToOne
        @identity_provider_factory = Authentication::AuthnJwt::CreateIdentityProvider
        @extract_resource_restrictions = Authentication::ResourceRestrictions::ExtractResourceRestrictions.new
        @validate_resource_restrictions = Authentication::ResourceRestrictions::ValidateResourceRestrictions.new(
          extract_resource_restrictions: @extract_resource_restrictions
        )
        @constraints = Authentication::Constraints::MultipleConstraint.new(
          Authentication::Constraints::NotEmptyConstraint.new
        )
      end

      def extract_token_from_credentials(credentials)
        @extract_token_from_credentials.call(credentials: credentials)
      end

      def jwt_identity(authentication_parameters)
        identity_provider = Authentication::AuthnJwt::CreateIdentityProvider.new.call(
          authentication_parameters: authentication_parameters
        )
        identity_provider.provide_jwt_identity
      end

      def validate_restrictions(authentication_parameters)
        @validate_resource_restrictions.call(
          authenticator_name: authentication_parameters.authenticator_name,
          service_id: authentication_parameters.service_id,
          account: authentication_parameters.account,
          role_name: authentication_parameters.jwt_identity,
          constraints: @constraints,
          authentication_request: @restriction_validator.new(
            decoded_token: authentication_parameters.decoded_token
          )
        )
      end

      def validate_and_decode_token(authentication_parameters)
        set_authentication_parameters(authentication_parameters)
        initialize_validate_and_decode_token
        @validate_and_decode_token.call(
          authentication_parameters: authentication_parameters
        )
      end

      private

      def set_authentication_parameters(authentication_parameters)
        @authentication_parameters = authentication_parameters
      end

      def initialize_validate_and_decode_token
        initialize_validate_and_decode_token_dependencies
        @validate_and_decode_token ||= @validate_and_decode_token_class.new(
          fetch_signing_key: fetch_signing_key,
          fetch_jwt_claims_to_validate: fetch_jwt_claims_to_validate
        )
      end

      def initialize_validate_and_decode_token_dependencies
        fetch_signing_key
        fetch_jwt_claims_to_validate
      end

      def fetch_signing_key
        @fetch_signing_key ||= fetch_cached_signing_key
      end

      def fetch_cached_signing_key
        @fetch_cached_signing_key ||= ::Util::ConcurrencyLimitedCache.new(
          ::Util::RateLimitedCache.new(
            ::Authentication::AuthnJwt::FetchCachedSigningKey.new(
              fetch_singing_key_interface: fetch_singing_key_interface
            ),
            refreshes_per_interval: CACHE_REFRESHES_PER_INTERVAL,
            rate_limit_interval: CACHE_RATE_LIMIT_INTERVAL,
            logger: Rails.logger
          ),
          max_concurrent_requests: CACHE_MAX_CONCURRENT_REQUESTS,
          logger: Rails.logger
        )
      end

      def fetch_singing_key_interface
        @fetch_singing_key_interface ||= create_signing_key_interface.call(
          authentication_parameters: @authentication_parameters
        )
      end

      def create_signing_key_interface
        @create_signing_key_interface ||= Authentication::AuthnJwt::CreateSigningKeyInterface.new
      end

      def fetch_jwt_claims_to_validate
        @fetch_jwt_claims_to_validate ||= ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new
      end
    end
  end
end
