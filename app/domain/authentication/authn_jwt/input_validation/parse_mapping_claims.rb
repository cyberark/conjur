module Authentication
  module AuthnJwt
    module InputValidation
      # Parse claim-aliases secret value and return a validated alias hashtable
      ParseClaimAliases ||= CommandClass.new(
        dependencies: {
          validate_claim_name: ValidateClaimName.new(
            deny_claims_list_value: CLAIMS_DENY_LIST
          ),
          logger: Rails.logger
        },
        inputs: %i[claim_aliases]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsingClaimAliases.new(@claim_aliases))
          validate_claim_aliases_secret_value_exists
          validate_claim_aliases_value_string
          validate_claim_aliases_list_values
          @logger.debug(LogMessages::Authentication::AuthnJwt::ParsedClaimAliases.new(alias_hash))
          alias_hash
        end

        private

        def validate_claim_aliases_secret_value_exists
          raise Errors::Authentication::AuthnJwt::ClaimAliasesMissingInput if
          @claim_aliases.blank?
        end

        def validate_claim_aliases_value_string
          validate_last_symbol_is_not_list_delimiter
          validate_array_after_split
        end

        def validate_last_symbol_is_not_list_delimiter
          # split ignores empty values at the end of string
          # ",,ddd,,,,,".split(",") == ["", "", "ddd"]
          raise Errors::Authentication::AuthnJwt::ClaimAliasesBlankOrEmpty, @claim_aliases if
            claim_aliases_last_character == CLAIMS_CHARACTER_DELIMITER
        end

        def claim_aliases_last_character
          @claim_aliases_last_character ||= @claim_aliases[-1]
        end

        def validate_array_after_split
          raise Errors::Authentication::AuthnJwt::ClaimAliasesBlankOrEmpty, @claim_aliases if
            alias_tuples_list.empty?
        end

        def alias_tuples_list
          @alias_tuples ||= @claim_aliases
            .split(CLAIMS_CHARACTER_DELIMITER)
            .map { |value| value.strip }
        end

        def validate_claim_aliases_list_values
          alias_tuples_list.each do |tuple|
            raise Errors::Authentication::AuthnJwt::ClaimAliasesBlankOrEmpty, @claim_aliases if
              tuple.blank?

            annotation_name, claim_name = alias_tuple_values(tuple)
            add_to_alias_hash(annotation_name, claim_name)
          end
        end

        def alias_tuple_values(tuple)
          values = tuple
            .split(TUPLE_CHARACTER_DELIMITER)
            .map { |value| value.strip }
          raise Errors::Authentication::AuthnJwt::ClaimAliasInvalidFormat, tuple unless values.length == 2

          [valid_claim_value(values[0], tuple),
           valid_claim_value(values[1], tuple)]
        end

        def valid_claim_value(value, tuple)
          raise Errors::Authentication::AuthnJwt::ClaimAliasInvalidFormat, tuple if value.blank?

          begin
            @validate_claim_name.call(
              claim_name: value
            )
          rescue => e
            raise Errors::Authentication::AuthnJwt::ClaimAliasInvalidClaimFormat.new(tuple, e.inspect)
          end
          value
        end

        def add_to_alias_hash(annotation_name, claim_name)
          raise Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError.new('annotation name', annotation_name) unless
            key_set.add?(annotation_name)
          raise Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError.new('claim name', claim_name) unless
            value_set.add?(claim_name)

          @logger.debug(LogMessages::Authentication::AuthnJwt::ClaimMapDefinition.new(annotation_name, claim_name))
          alias_hash[annotation_name] = claim_name
        end

        def key_set
          @key_set ||= Set.new
        end

        def value_set
          @value_set ||= Set.new
        end

        def alias_hash
          @alias_hash ||= {}
        end
      end
    end
  end
end
