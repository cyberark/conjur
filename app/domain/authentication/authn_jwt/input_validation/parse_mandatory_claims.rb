module Authentication
  module AuthnJwt
    module InputValidation
      # Parse mandatory-claims secret value and return a validated claims list
      ParseMandatoryClaims ||= CommandClass.new(
        dependencies: {
          validate_claim_name: ValidateClaimName.new(
            deny_claims_list_value: MANDATORY_CLAIMS_DENY_LIST
          ),
          logger: Rails.logger
        },
        inputs: %i[mandatory_claims_secret_value]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsingMandatoryClaims.new(@mandatory_claims_secret_value))
          validate_mandatory_claims_secret_value_exists
          validate_mandatory_claims_list_format
          validate_mandatory_claims_list_value
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsedMandatoryClaims.new(parsed_mandatory_claims_list))

          parsed_mandatory_claims_list
        end

        private

        def validate_mandatory_claims_secret_value_exists
          raise Errors::Authentication::AuthnJwt::FailedToParseMandatoryClaimsMissingInput if @mandatory_claims_secret_value.blank?
        end
        
        def validate_mandatory_claims_list_format
          validate_delimiter_format
          validate_empty_values
          validate_duplications
        end

        def validate_delimiter_format
          if mandatory_claims_secret_value_starts_or_ends_with_delimiter
            raise Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat
          end
        end
        
        def mandatory_claims_secret_value_starts_or_ends_with_delimiter
          return if mandatory_claims_secret_value_first_character == MANDATORY_CLAIMS_CHARACTER_DELIMITER ||
              mandatory_claims_secret_value_last_character == MANDATORY_CLAIMS_CHARACTER_DELIMITER
        end
          
        def mandatory_claims_secret_value_first_character
          @mandatory_claims_secret_value_first_character ||= @mandatory_claims_secret_value_first_character[0, 1]
        end

        def mandatory_claims_secret_value_last_character
          @mandatory_claims_secret_value_last_character ||= @mandatory_claims_secret_value_first_character[-1]
        end
        
        def validate_empty_values
          if parsed_mandatory_claims_list.include?(' ') 
            raise Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat, @mandatory_claims_secret_value 
          end
        end

        def validate_duplications
          if parsed_mandatory_claims_list.uniq.length != parsed_mandatory_claims_list.length
            raise Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat, @mandatory_claims_secret_value
          end
        end
        
        def parsed_mandatory_claims_list
          @parsed_mandatory_claims_list || mandatory_claims_secret_value_trim.split(MANDATORY_CLAIMS_CHARACTER_DELIMITER)
        end
        
        def mandatory_claims_secret_value_trim
          @mandatory_claims_secret_value_trim ||= @mandatory_claims_secret_value.delete(' ')
        end
        
        def validate_mandatory_claims_list_value
          # TODO: for each claim run validate_claim_name command class 
        end
      end
    end
  end
end
