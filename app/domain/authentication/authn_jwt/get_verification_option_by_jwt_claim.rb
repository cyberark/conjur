module Authentication
  module AuthnJwt
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
        raise Errors::Authentication::AuthnJwt::MissingClaim.new if @jwt_claim.blank?
      end

      def get_verification_option_by_jwt_claim
        @logger.debug(LogMessages::Authentication::AuthnJwt::ConvertingJwtClaimToVerificationOption.new(@jwt_claim.name))

        case @jwt_claim.name
        when EXP_CLAIM_NAME, NBF_CLAIM_NAME
          @verification_option = {}
        when ISS_CLAIM_NAME
          raise Errors::Authentication::AuthnJwt::MissingClaimValue.new(@jwt_claim.name) if @jwt_claim.value.blank?
          @verification_option = {:iss => @jwt_claim.value, :verify_iss => true}
        when IAT_CLAIM_NAME
          @verification_option = {:verify_iat => true}
        else
          raise Errors::Authentication::AuthnJwt::UnsupportedClaim.new(@jwt_claim.name)
        end

        @logger.debug(
          LogMessages::Authentication::AuthnJwt::ConvertedJwtClaimToVerificationOption.new(
            @jwt_claim.name,
            @verification_option.to_s
          )
        )

        @verification_option
      end
    end
  end
end
