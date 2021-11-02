module Authentication
  module AuthnJwt
    module InputValidation
      # Validate the claim name value
      ValidateClaimName ||= CommandClass.new(
        dependencies: {
          regexp_class: Regexp,
          deny_claims_list_value: [],
          logger: Rails.logger
        },
        inputs: %i[claim_name]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingClaimName.new(@claim_name))
          validate_claim_name_exists
          validate_claim_name_value
          validate_claim_is_allowed
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedClaimName.new(@claim_name))
        end

        private

        def validate_claim_name_exists
          raise Errors::Authentication::AuthnJwt::FailedToValidateClaimMissingClaimName if @claim_name.blank?
        end

        def validate_claim_name_value
          return if valid_claim_name_regex.match?(@claim_name)

          raise Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName.new(
            @claim_name,
            valid_claim_name_regex
          )
        end
        
        def valid_claim_name_regex
          @valid_claim_name_regex ||= Regexp.new(PURE_NESTED_CLAIM_NAME_REGEX)
        end
        
        def validate_claim_is_allowed
          @logger.debug(LogMessages::Authentication::AuthnJwt::ClaimsDenyListValue.new(@deny_claims_list_value))
          return if @deny_claims_list_value.blank?

          if @deny_claims_list_value.include?(@claim_name)
            raise Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList.new(
              @claim_name,
              @deny_claims_list_value
            )
          end
        end
      end
    end
  end
end
