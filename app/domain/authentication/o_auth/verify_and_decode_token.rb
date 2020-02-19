require 'jwt'

module Authentication
  module OAuth

    Err = Errors::Authentication::OAuth
    Log = LogMessages::Authentication::OAuth
    # Possible Errors Raised:
    # TokenExpired, TokenDecodeFailed, TokenVerifyFailed

    # This class decodes and verifies JWT tokens, issued by an OAuthn 2.0 Identity Provider.
    # It first retrieves the JWKs from the identity provider and sets them as verification options
    # for Authentication::Jwt::VerifyAndDecodeToken. That class does the offline verification and decode,
    # using the JWKs retrieved from the OAuthn 2.0 Identity Provider.
    VerifyAndDecodeToken = CommandClass.new(
      dependencies: {
        # We have a ConcurrencyLimitedCache which wraps a RateLimitedCache which wraps a FetchProviderCertificate class
        fetch_provider_certificate: ::Util::ConcurrencyLimitedCache.new(
          ::Util::RateLimitedCache.new(
            ::Authentication::OAuth::FetchProviderCertificates.new,
            refreshes_per_interval: 10,
            rate_limit_interval:    300, # 300 seconds (every 5 mins)
            logger: Rails.logger
          ),
          max_concurrent_requests: 3, # TODO: Should be dynamic calculation
          logger: Rails.logger
        ),
        verify_and_decode_token: ::Authentication::Jwt::VerifyAndDecodeToken.new,
        logger:                     Rails.logger
      },
      inputs:       %i(provider_uri token_jwt claims_to_verify)
    ) do

      def call
        fetch_certs
        verify_and_decode_token
      end

      private

      def fetch_certs(force_read: false)
        provider_certificates = @fetch_provider_certificate.call(
          provider_uri: @provider_uri,
          refresh: force_read
        )

        @jwks = provider_certificates.jwks
        @algs = provider_certificates.algorithms
        @logger.debug(Log::IdentityProviderCertificateFetchedFromCache.new)
      end

      def verify_and_decode_token
        ensure_certs_are_fresh
        verified_and_decoded_token
      end

      def ensure_certs_are_fresh
        verified_and_decoded_token
      rescue
        @logger.debug(Log::ValidateProviderCertificateIsUpdated.new)
        # maybe failed due to certificate rotation. Force cache to read it again
        fetch_certs(force_read: true)
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
