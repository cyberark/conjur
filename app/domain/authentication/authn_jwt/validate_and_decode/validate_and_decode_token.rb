module Authentication
  module AuthnJwt
    module ValidateAndDecode
      # ValidateAndDecodeToken command class is responsible to validate the JWT token 2 times:
      # 1st we are validating only the signature.
      # 2nd we are validating the claims, by checking the token content to decide which claims are enforced
      # for the 2nd validation
      ValidateAndDecodeToken ||= CommandClass.new(
        dependencies: {
          verify_and_decode_token: ::Authentication::Jwt::VerifyAndDecodeToken.new,
          fetch_jwt_claims_to_validate: ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new,
          get_verification_option_by_jwt_claim: ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new,
          create_signing_key_provider: ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyProvider.new,
          logger: Rails.logger
        },
        inputs: %i[authenticator_input jwt_token]
      ) do
        extend(Forwardable)

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingToken.new)
          validate_token_exists
          fetch_signing_key
          validate_signature
          fetch_jwt_claims_to_validate
          validate_claims
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedToken.new)

          decoded_and_validated_token_with_claims
        end

        private

        def signing_key_provider
          @signing_key_provider ||= @create_signing_key_provider.call(
            authenticator_input: @authenticator_input
          )
        end

        def validate_token_exists
          raise Errors::Authentication::AuthnJwt::MissingToken if @jwt_token.blank?
        end

        def fetch_signing_key(force_fetch: false)
          @jwks = signing_key_provider.call(
            force_fetch: force_fetch
          )
          @logger.debug(LogMessages::Authentication::AuthnJwt::SigningKeysFetchedFromCache.new)
        end

        def validate_signature
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingTokenSignature.new)
          ensure_keys_are_fresh
          fetch_decoded_token_for_signature_only
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedTokenSignature.new)
        end

        def ensure_keys_are_fresh
          fetch_decoded_token_for_signature_only
        rescue
          @logger.debug(
            LogMessages::Authentication::AuthnJwt::ValidateSigningKeysAreUpdated.new
          )
          # maybe failed due to keys rotation. Force cache to read it again
          fetch_signing_key(force_fetch: true)
        end

        def fetch_decoded_token_for_signature_only
          decoded_token_for_signature_only
        end

        def decoded_token_for_signature_only
          @decoded_token_for_signature_only ||= decoded_token(verification_options_for_signature_only)
        end

        def verification_options_for_signature_only
          @verification_options_for_signature_only = {
            algorithms: SUPPORTED_ALGORITHMS,
            jwks: @jwks
          }
        end

        def decoded_token(verification_options)
          @decoded_token = @verify_and_decode_token.call(
            token_jwt: @jwt_token,
            verification_options: verification_options
          )
        end

        def fetch_jwt_claims_to_validate
          claims_to_validate
        end

        def claims_to_validate
          @claims_to_validate ||= @fetch_jwt_claims_to_validate.call(
            authenticator_input: @authenticator_input,
            decoded_token: fetch_decoded_token_for_signature_only
          )
        end

        def validate_claims
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingTokenClaims.new)

          claims_to_validate.each do |jwt_claim|
            claim_name = jwt_claim.name
            if @decoded_token[claim_name].blank?
              raise Errors::Authentication::AuthnJwt::MissingMandatoryClaim, claim_name
            end

            verification_option = @get_verification_option_by_jwt_claim.call(jwt_claim: jwt_claim)
            add_to_verification_options_with_claims(verification_option)
          end

          validate_token_with_claims
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedTokenClaims.new)
        end

        def add_to_verification_options_with_claims(verification_option)
          @verification_options_with_claims = verification_options_with_claims.merge(verification_option)
        end

        def verification_options_with_claims
          @verification_options_with_claims ||= verification_options_for_signature_only
        end

        def validate_token_with_claims
          decoded_and_validated_token_with_claims
        end

        def decoded_and_validated_token_with_claims
          @decoded_and_validated_token_with_claims ||= decoded_token(verification_options_with_claims)
        end
      end
    end
  end
end
