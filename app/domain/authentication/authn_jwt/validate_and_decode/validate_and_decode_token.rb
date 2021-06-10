module Authentication
  module AuthnJwt
    module ValidateAndDecode
      # ValidateAndDecodeToken command class is responsible to validate the JWT token 2 times:
      # 1st we are validating only the signature.
      # 2nd we are validating the claims, by checking the token content to decide which claims are mandatory
      # for the 2nd validation
      ValidateAndDecodeToken ||= CommandClass.new(
        dependencies: {
          fetch_signing_key: ::Authentication::AuthnJwt::SigningKey::FetchSigningKeyInterface,
          verify_and_decode_token: ::Authentication::Jwt::VerifyAndDecodeToken.new,
          fetch_jwt_claims_to_validate: ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new,
          get_verification_option_by_jwt_claim: ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
        extend(Forwardable)
        def_delegators(:@authentication_parameters, :jwt_token)

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingToken.new)
          validate_token_exists
          fetch_signing_key
          validate_signature
          fetch_jwt_claims_to_validate
          validate_claims
          decoded_token_after_claims_validation
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedToken.new)

          @decoded_token_after_claims_validation
        end

        private

        def validate_token_exists
          raise Errors::Authentication::AuthnJwt::MissingToken if jwt_token.blank?
        end

        def fetch_signing_key(force_read: false)
          @jwks = @fetch_signing_key.call(refresh: force_read)
          @logger.debug(LogMessages::Authentication::AuthnJwt::SigningKeysFetchedFromCache.new)
        end

        def validate_signature
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingTokenSignature.new)
          ensure_keys_are_fresh
          decoded_token_after_signature_only_validation
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedTokenSignature.new)
        end

        def ensure_keys_are_fresh
          decoded_token_after_signature_only_validation
        rescue
          @logger.debug(
            LogMessages::Authentication::AuthnJwt::ValidateSigningKeysAreUpdated.new
          )
          # maybe failed due to keys rotation. Force cache to read it again
          fetch_signing_key(force_read: true)
        end

        def decoded_token_after_signature_only_validation
          @decoded_token_after_signature_only_validation ||= decoded_token(verification_options_for_signature_only)
        end

        def verification_options_for_signature_only
          @verification_options_for_signature_only = {
            algorithms: algorithms,
            jwks: @jwks
          }
        end

        def algorithms
          @algorithms ||= SUPPORTED_ALGORITHMS
        end

        def decoded_token(verification_options)
          @decoded_token = @verify_and_decode_token.call(
            token_jwt: jwt_token,
            verification_options: verification_options
          )
        end

        def fetch_jwt_claims_to_validate
          update_authentication_parameters_with_decoded_token
          claims_to_validate
        end

        def update_authentication_parameters_with_decoded_token
          @authentication_parameters.decoded_token = decoded_token_after_signature_only_validation
        end

        def claims_to_validate
          @claims_to_validate ||= @fetch_jwt_claims_to_validate.call(
            authentication_parameters: @authentication_parameters
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
          decoded_token_after_claims_validation
        end

        def decoded_token_after_claims_validation
          @decoded_token_after_claims_validation ||= decoded_token(verification_options_with_claims)
        end
      end
    end
  end
end
