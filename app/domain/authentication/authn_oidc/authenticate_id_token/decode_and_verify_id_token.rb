module Authentication
  module AuthnOidc
    module AuthenticateIdToken

      Log = LogMessages::Authentication::AuthnOidc
      Err = Errors::Authentication::AuthnOidc
      # Possible Errors Raised:
      # IdTokenExpired, IdTokenVerifyFailed, IdTokenInvalidFormat

      DecodeAndVerifyIdToken = CommandClass.new(
        dependencies: {
          fetch_provider_certificate: ::Util::RateLimitedCache.new(
            ::Authentication::AuthnOidc::AuthenticateIdToken::FetchProviderCertificate.new,
            refreshes_per_interval: 10,
            rate_limit_interval: 300, # 300 seconds (every 5 mins)
          ),
          logger: Rails.logger
        },
        inputs: %i(provider_uri id_token_jwt)
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

        # Note: At this point `validate_id_token` will have already been called
        # and `decoded_id_token` will just return the memoized value, so nothing
        # is really "happening" here.  Nevertheless, the steps `validate_id_token`
        # and `decoded_id_token` are semantically distinct.  The former has 
        # the responsiblity of raising an error.  The latter of logging the success.
        # Also, it is merely a coincidental implementation detail that validate_id_token
        # happens to validate by calling `decoded_id_token` and checking if it errors
        def decode_id_token
          decoded_id_token
          @logger.debug(Log::IDTokenDecodeSuccess.new.to_s)
        end

        def verify_token_claims
          # Verify id_token expiration. OpenIDConnect requires to verify few claims.
          # Mask required claims such that effectively only expiration will be verified
          expected = { client_id: decoded_attributes[:aud] || decoded_attributes[:client_id],
                       issuer: decoded_attributes[:iss],
                       nonce: decoded_attributes[:nonce] }

          decoded_id_token.verify!(expected)
          @logger.debug(Log::IDTokenVerificationSuccess.new.to_s)
        rescue OpenIDConnect::ResponseObject::IdToken::ExpiredToken
          raise Err::IdTokenExpired
        rescue => e
          raise Err::IdTokenVerifyFailed, e.inspect
        end

        def fetch_certs(force_read: false)
          @certs = @fetch_provider_certificate.(
            provider_uri: @provider_uri,
            refresh: force_read
          )
        end

        def decoded_attributes
          @decoded_attributes ||= decoded_id_token.raw_attributes
        end

        def ensure_certs_are_fresh
          decoded_id_token
        rescue
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

        def decoded_id_token
          @decoded_id_token ||= OpenIDConnect::ResponseObject::IdToken.decode(
            @id_token_jwt,
            @certs
          )
        end

      end
    end
  end
end
