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
        inputs: %i[mandatory_claims]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsingMandatoryClaims.new(@mandatory_claims))
          validate_mandatory_claims_exists
          validate_mandatory_claims_list_format
          validate_mandatory_claims_list_value
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsedMandatoryClaims.new(parsed_mandatory_claims_list))

          parsed_mandatory_claims_list
        end

        private

        def validate_mandatory_claims_exists
          raise Errors::Authentication::AuthnJwt::FailedToParseMandatoryClaimsMissingInput if @mandatory_claims.blank?
        end
        
        def validate_mandatory_claims_list_format
          validate_delimiter_format
          validate_duplications
        end

        def validate_delimiter_format
          if mandatory_claims_starts_or_ends_with_delimiter? || 
              mandatory_claims_has_connected_delimiter?
            raise Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat, @mandatory_claims
          end
        end
        
        def mandatory_claims_starts_or_ends_with_delimiter?
          mandatory_claims_first_character == CLAIMS_CHARACTER_DELIMITER ||
            mandatory_claims_last_character == CLAIMS_CHARACTER_DELIMITER
        end
          
        def mandatory_claims_first_character
          @mandatory_claims_first_character ||= @mandatory_claims[0, 1]
        end

        def mandatory_claims_last_character
          @mandatory_claims_last_character ||= @mandatory_claims[-1]
        end
        
        def mandatory_claims_has_connected_delimiter?
          parsed_mandatory_claims_list.include?('')
        end

        def validate_duplications
          if parsed_mandatory_claims_list.uniq.length != parsed_mandatory_claims_list.length
            raise Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormatContainsDuplication, @mandatory_claims
          end
        end
        
        def parsed_mandatory_claims_list
          @parsed_mandatory_claims_list ||= mandatory_claims_strip_claims
        end

        def mandatory_claims_split_by_delimiter
          @mandatory_claims_split_by_delimiter ||= @mandatory_claims.split(CLAIMS_CHARACTER_DELIMITER)
        end
        
        def mandatory_claims_strip_claims
          @mandatory_claims_strip_claims ||= mandatory_claims_split_by_delimiter.collect(&:strip)
        end
        
        
        def validate_mandatory_claims_list_value
          parsed_mandatory_claims_list.each do |claim_name|
            @validate_claim_name.call(claim_name: claim_name)
          end
        end
      end
    end
  end
end
