module Authentication
  module AuthnJwt
    module InputValidation
      # Parse enforced-claims secret value and return a validated claims list
      ParseEnforcedClaims ||= CommandClass.new(
        dependencies: {
          validate_claim_name: ValidateClaimName.new(
            deny_claims_list_value: CLAIMS_DENY_LIST
          ),
          logger: Rails.logger
        },
        inputs: %i[enforced_claims]
      ) do

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsingEnforcedClaims.new(@enforced_claims))
          validate_enforced_claims_exists
          validate_enforced_claims_list_format
          validate_enforced_claims_list_value
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsedEnforcedClaims.new(parsed_enforced_claims_list))

          parsed_enforced_claims_list
        end

        private

        def validate_enforced_claims_exists
          raise Errors::Authentication::AuthnJwt::FailedToParseEnforcedClaimsMissingInput if @enforced_claims.blank?
        end
        
        def validate_enforced_claims_list_format
          validate_delimiter_format
          validate_duplications
        end

        def validate_delimiter_format
          if enforced_claims_starts_or_ends_with_delimiter? || 
              enforced_claims_has_connected_delimiter?
            raise Errors::Authentication::AuthnJwt::InvalidEnforcedClaimsFormat, @enforced_claims
          end
        end
        
        def enforced_claims_starts_or_ends_with_delimiter?
          enforced_claims_first_character == CLAIMS_CHARACTER_DELIMITER ||
            enforced_claims_last_character == CLAIMS_CHARACTER_DELIMITER
        end
          
        def enforced_claims_first_character
          @enforced_claims_first_character ||= @enforced_claims[0, 1]
        end

        def enforced_claims_last_character
          @enforced_claims_last_character ||= @enforced_claims[-1]
        end
        
        def enforced_claims_has_connected_delimiter?
          parsed_enforced_claims_list.include?('')
        end

        def validate_duplications
          return unless parsed_enforced_claims_list.uniq.length != parsed_enforced_claims_list.length

          raise Errors::Authentication::AuthnJwt::InvalidEnforcedClaimsFormatContainsDuplication, @enforced_claims
        end
        
        def parsed_enforced_claims_list
          @parsed_enforced_claims_list ||= enforced_claims_strip_claims
        end

        def enforced_claims_split_by_delimiter
          @enforced_claims_split_by_delimiter ||= @enforced_claims.split(CLAIMS_CHARACTER_DELIMITER)
        end
        
        def enforced_claims_strip_claims
          @enforced_claims_strip_claims ||= enforced_claims_split_by_delimiter.collect(&:strip)
        end
        
        def validate_enforced_claims_list_value
          parsed_enforced_claims_list.each do |claim_name|
            @validate_claim_name.call(claim_name: claim_name)
          end
        end
      end
    end
  end
end
