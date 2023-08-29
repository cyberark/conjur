require 'jwt'

module Authentication
  module OAuth

    # This class decodes and verifies JWT tokens, issued by an OAuthn 2.0 Identity Provider.
    # It first retrieves the JWKs from the identity provider and sets them as verification options
    # for Authentication::Jwt::VerifyAndDecodeToken. That class does the offline verification and decode,
    # using the JWKs retrieved from the OAuthn 2.0 Identity Provider.
    VerifyAndDecodeToken = CommandClass.new(
      dependencies: {
        # We have a ConcurrencyLimitedCache which wraps a RateLimitedCache which wraps a FetchProviderKeys class
        fetch_provider_keys: ::Util::ConcurrencyLimitedCache.new(
          ::Util::RateLimitedCache.new(
            FetchProviderKeys.new,
            refreshes_per_interval: 10,
            rate_limit_interval: 300, # 300 seconds (every 5 mins)
            logger: Rails.logger
          ),
          max_concurrent_requests: 3, # TODO: Should be dynamic calculation
          logger: Rails.logger
        ),
        verify_and_decode_token: ::Authentication::Jwt::VerifyAndDecodeToken.new,
        logger: Rails.logger
      },
      inputs: %i[provider_uri token_jwt claims_to_verify ca_cert]
    ) do
      def call
        fetch_provider_keys
        verify_and_decode_token
      end

      private

      def fetch_provider_keys(force_read: false)
        provider_keys = @fetch_provider_keys.call(
          provider_uri: @provider_uri,
          refresh: force_read,
          ca_cert: @ca_cert
        )

        @jwks = provider_keys.jwks
        @algs = provider_keys.algorithms
        @logger.debug(
          LogMessages::Authentication::OAuth::IdentityProviderKeysFetchedFromCache.new
        )
      end

      # ensure_keys_are_fresh will try to verify and decode the token and if it
      # fails we fetch the provider keys again. We then verify and decode again
      # so we definitely don't fail because the keys are too old. If ensure_keys_are_fresh
      # will succeed to decode the token then the call to verified_and_decoded_token
      # will not do a thing because the object is memoized
      def verify_and_decode_token
        ensure_keys_are_fresh
        verified_and_decoded_token
      end

      def ensure_keys_are_fresh
        verified_and_decoded_token
      rescue
        @logger.debug(
          LogMessages::Authentication::OAuth::ValidateProviderKeysAreUpdated.new
        )
        # maybe failed due to keys rotation. Force cache to read it again
        fetch_provider_keys(force_read: true)
      end

      def verified_and_decoded_token
        @verified_and_decoded_token ||= @verify_and_decode_token.call(
          token_jwt: @token_jwt,
          verification_options: verification_options
        )
      end

      def verification_options
        @verification_options ||= {
          algorithms: @algs,
          jwks: @jwks
        }.merge(@claims_to_verify)
      end
    end
  end
end
