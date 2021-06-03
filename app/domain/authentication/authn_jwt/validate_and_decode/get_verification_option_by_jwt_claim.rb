module Authentication
  module AuthnJwt
    module ValidateAndDecode
      # GetVerificationOptionByJwtClaim command class is responsible to get jwt claim and return his verification option,
      # in order to validate it against JWT 3rd party, for example:
      # 1. Input: {name: iss, value: cyberark.com} // jwt claim
      #    Output: {:iss => cyberark.com, :verify_iss => true} // verification option dictionary
      # 2. Input: {name: iat, value: } // jwt claim
      #    Output: {:verify_iat => true} // verification option dictionary
      # 3. Input: {name: exp, value: } // jwt claim
      #    Output: {} // verification option dictionary
      # 4. Input: {name: nbf, value: } // jwt claim
      #    Output: {} // verification option dictionary
      GetVerificationOptionByJwtClaim ||= CommandClass.new(
        dependencies: {
          logger: Rails.logger
        },
        inputs: [:jwt_claim]
      ) do
        def call
          validate_claim_exists
          get_verification_option_by_jwt_claim
        end

        private

        def validate_claim_exists
          raise Errors::Authentication::AuthnJwt::MissingClaim if @jwt_claim.blank?
        end

        def get_verification_option_by_jwt_claim
          claim_value = @jwt_claim.value
          claim_name = @jwt_claim.name
          @logger.debug(LogMessages::Authentication::AuthnJwt::ConvertingJwtClaimToVerificationOption.new(claim_name))

          case claim_name
          when EXP_CLAIM_NAME, NBF_CLAIM_NAME
            @verification_option = {}
          when ISS_CLAIM_NAME
            raise Errors::Authentication::AuthnJwt::MissingClaimValue, claim_name if claim_value.blank?

            @verification_option = { iss: claim_value, verify_iss: true }
          when IAT_CLAIM_NAME
            @verification_option = { verify_iat: true }
          else
            raise Errors::Authentication::AuthnJwt::UnsupportedClaim, claim_name
          end

          @logger.debug(
            LogMessages::Authentication::AuthnJwt::ConvertedJwtClaimToVerificationOption.new(
              claim_name,
              @verification_option.to_s
            )
          )

          @verification_option
        end
      end
    end
  end
end
