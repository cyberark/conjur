require 'jwt'

module Authentication
  module OAuth

    Err = Errors::Authentication::OAuth
    Log = LogMessages::Authentication::OAuth
    # Possible Errors Raised:
    # TokenExpired, TokenDecodeFailed, TokenVerifyFailed

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
        return @decoded_token unless @decoded_token.nil?

        options = {
          algorithms: @algs,
          jwks: @jwks
        }.merge(@claims_to_verify)

        # JWT.decode returns an array with one decoded token so we take the first object
        @decoded_token = JWT.decode(
          @token_jwt,
          nil, # the key will be taken from options[:jwks]
          true, # indicates that we should verify the token
          options
        ).first.tap do
          @logger.debug(Log::TokenDecodeSuccess.new)
        end
      rescue JWT::ExpiredSignature
        raise Err::TokenExpired
      rescue JWT::DecodeError
        @logger.debug(Log::TokenDecodeFailed.new(e.inspect))
        raise Err::TokenDecodeFailed, e.inspect
      rescue => e
        raise Err::TokenVerifyFailed, e.inspect
      end
    end
  end
end
