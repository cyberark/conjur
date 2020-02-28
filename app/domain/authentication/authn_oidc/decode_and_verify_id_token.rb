module Authentication
  module AuthnOidc

    Log ||= LogMessages::Authentication::AuthnOidc
    Err ||= Errors::Authentication::AuthnOidc
    # Possible Errors Raised:
    # IdTokenExpired, IdTokenVerifyFailed, IdTokenInvalidFormat

    DecodeAndVerifyIdToken ||= CommandClass.new(
      dependencies: {
        # We have a ConcurrencyLimitedCache which wraps a RateLimitedCache which wraps a FetchProviderCertificate class
        fetch_provider_certificate: ::Util::ConcurrencyLimitedCache.new(
          ::Util::RateLimitedCache.new(
            ::Authentication::AuthnOidc::FetchProviderCertificate.new,
            refreshes_per_interval: 10,
            rate_limit_interval:    300, # 300 seconds (every 5 mins)
            logger: Rails.logger
          ),
          max_concurrent_requests: 3, # TODO: Should be dynamic calculation
          logger: Rails.logger
        ),
        logger:                     Rails.logger
      },
      inputs:       %i(provider_uri id_token_jwt)
    ) do

      def call
        fetch_certs
        ensure_certs_are_fresh
        validate_id_token
        decode_id_token
        verify_token_claims
        # TODO: In general we should be returning proper value objects rather
        # than raw hashes.
        decoded_attributes # return decoded attributes as hash
      end

      private

      def fetch_certs(force_read: false)
        @certs = @fetch_provider_certificate.(
          provider_uri: @provider_uri,
            refresh: force_read
        )
        @logger.debug(Log::OIDCProviderCertificateFetchedFromCache.new)
        @certs
      end

      def ensure_certs_are_fresh
        decoded_id_token
      rescue
        @logger.debug(Log::ValidateProviderCertificateIsUpdated.new)
        # maybe failed due to certificate rotation. Force cache to read it again
        fetch_certs(force_read: true)
      end

      # Note: Order matters here.  It is assumed this is called after
      #       `ensure_certs_are_fresh`.
      def validate_id_token
        decoded_id_token
      rescue => e
        raise Err::IdTokenInvalidFormat, e.inspect
      end

      # Note: At this point `validate_id_token` will have already been called
      # and `decoded_id_token` will just return the memoized value, so nothing
      # is really "happening" here.  This method is still in the `call` method
      # to tell the story
      def decode_id_token
        decoded_id_token
      end

      def verify_token_claims
        # Verify id_token expiration. OpenIDConnect requires to verify few claims.
        # Mask required claims such that effectively only expiration will be verified
        expected = { client_id: decoded_attributes[:aud] || decoded_attributes[:client_id],
                     issuer:    decoded_attributes[:iss],
                     nonce:     decoded_attributes[:nonce] }

        decoded_id_token.verify!(expected)
        @logger.debug(Log::IDTokenVerificationSuccess.new)
      rescue OpenIDConnect::ResponseObject::IdToken::ExpiredToken
        raise Err::IdTokenExpired
      rescue => e
        raise Err::IdTokenVerifyFailed, e.inspect
      end

      def decoded_id_token
        return @decoded_id_token unless @decoded_id_token.nil?
        @decoded_id_token = OpenIDConnect::ResponseObject::IdToken.decode(
          @id_token_jwt,
          @certs
        )
        @logger.debug(Log::IDTokenDecodeSuccess.new)
        @decoded_id_token
      rescue => e
        @logger.debug(Log::IDTokenDecodeFailed.new(e.inspect))
        raise e
      end

      def decoded_attributes
        @decoded_attributes ||= decoded_id_token.raw_attributes
      end
    end
  end
end
