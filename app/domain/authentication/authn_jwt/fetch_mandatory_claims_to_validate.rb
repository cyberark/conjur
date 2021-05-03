# frozen_string_literal: true

module Authentication
  module AuthnJwt
    OPTIONAL_CLAIMS = [ISS_CLAIM_NAME, EXP_CLAIM_NAME, NBF_CLAIM_NAME, IAT_CLAIM_NAME].freeze

    # FetchMandatoryClaimsToValidate command class is responsible to return a list of mandatory JWT standard claims to
    # validate.
    FetchMandatoryClaimsToValidate ||= CommandClass.new(
      dependencies: {
        fetch_issuer_value: ::Authentication::AuthnJwt::FetchIssuerValue.new,
        logger: Rails.logger
      },
      inputs: %i[authentication_parameters]
    ) do

      def call
        @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingJwtMandatoryClaimsToValidate.new)
        fetch_mandatory_claims_to_validate
        @logger.debug(LogMessages::Authentication::AuthnJwt::FetchedJwtMandatoryClaimsToValidate.new)

        mandatory_claims_to_validate
      end

      private

      # fetch_mandatory_claims_to_validate function is responsible to return a list of mandatory JWT standard claims to
      # validate, according to the following logic:
      # For each optional claim (iss, exp, nbf, iat) that exists in the token - add to mandatory list
      # Note: mandatory list also contains the value to validate if necessary (for example iss: cyberark.com)
      def fetch_mandatory_claims_to_validate
        OPTIONAL_CLAIMS.each do |optional_claim|
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingJwtOptionalClaimToValidate.new(optional_claim))

          if @authentication_parameters.decoded_token[optional_claim]
            add_to_mandatory_claims_list(optional_claim)
          end
        end
      end

      def add_to_mandatory_claims_list(claim)
        @logger.debug(LogMessages::Authentication::AuthnJwt::AddingJwtMandatoryClaimToValidate.new(claim))

        mandatory_claims_to_validate.push(
          ::Authentication::AuthnJwt::JwtMandatoryClaim.new(
            name: claim,
            value: claim_value(claim)
          )
        )
      end

      def mandatory_claims_to_validate
        @mandatory_claims_to_validate ||= []
      end

      def claim_value(claim)
        case claim
        when ISS_CLAIM_NAME
          return @fetch_issuer_value.(@authentication_parameters)
        else
          # Claims that do not need an additional value to be validated will be set with nil value
          # For example: exp, nbf, iat
          nil
        end
      end
    end
  end
end
