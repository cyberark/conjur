require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidation
      # Creating the needed constraints to check the host annotations:
      #   * NonEmptyConstraint - Checks at least one constraint is there
      #   * RequiredConstraint - Checks all the claims in "enforced_claims" variable are in host annotations. If there
      #     is mapping for this claim it will convert it to relevant name
      #   * NonPermittedConstraint - Checks there are no standard claims [exp,iat,nbf,iss] in the host annotations
      CreateConstrains = CommandClass.new(
        dependencies: {
          non_permitted_constraint_class: Authentication::Constraints::NonPermittedConstraint,
          required_constraint_class: Authentication::Constraints::RequiredConstraint,
          multiple_constraint_class: Authentication::Constraints::MultipleConstraint,
          not_empty_constraint: Authentication::Constraints::NotEmptyConstraint.new,
          fetch_enforced_claims: Authentication::AuthnJwt::RestrictionValidation::FetchEnforcedClaims.new,
          fetch_mapping_claims_class: Authentication::AuthnJwt::RestrictionValidation::FetchMappingClaims,
          logger: Rails.logger
        },
        inputs: %i[jwt_authenticator_input base_non_permitted_annotations]
      ) do
        # These is command class so only call is called from outside. Other functions are needed here.
        # :reek:TooManyMethods
        def call
          @logger.info(LogMessages::Authentication::AuthnJwt::CreateContraintsFromPolicy.new)
          fetch_enforced_claims
          fetch_mapping_claims
          map_enforced_claims
          init_constraints_list
          add_non_empty_constraint
          add_required_constraint
          add_non_permitted_constraint
          create_multiple_constraint
          @logger.info(LogMessages::Authentication::AuthnJwt::CreatedConstraintsFromPolicy.new)
          multiple_constraint
        end

        private

        def init_constraints_list
          @constraints = []
        end

        def add_non_empty_constraint
          @constraints.append(@not_empty_constraint)
        end

        # Call should tell a story but
        # :reek:EnforcedStyleForLeadingUnderscores
        def fetch_enforced_claims
          enforced_claims
        end

        def map_enforced_claims
          mapped_enforced_claims
        end

        def mapped_enforced_claims
          @mapped_enforced_claims ||= enforced_claims.map { |claim| convert_claim(claim) }
        end

        def convert_claim(claim)
          if mapping_claims.include?(claim)
            claim_reference = mapping_claims[claim]
            @logger.debug(LogMessages::Authentication::AuthnJwt::ConvertingClaimAccordingToMapping.new(claim, claim_reference))
            return claim_reference
          end
          claim
        end

        def fetch_mapping_claims
          mapping_claims
        end

        def add_required_constraint
          @constraints.append(required_constraint)
        end

        def non_permitted_constraint
          @non_permitted_constraint ||= @non_permitted_constraint_class.new(
            non_permitted: @base_non_permitted_annotations + mapping_claims.keys
          )
        end

        def add_non_permitted_constraint
          @constraints.append(non_permitted_constraint)
        end

        def create_multiple_constraint
          multiple_constraint
        end

        def enforced_claims
          @enforced_claims ||= @fetch_enforced_claims.call(
            jwt_authenticator_input: @jwt_authenticator_input
          )
        end

        def mapping_claims
          @mapping_claims ||= @fetch_mapping_claims_class.new.call(
            jwt_authenticator_input: @jwt_authenticator_input
          ).invert
        end

        def required_constraint
          @logger.debug(LogMessages::Authentication::AuthnJwt::ConstraintsFromEnforcedClaims.new(mapped_enforced_claims))
          @required_constraint ||= @required_constraint_class.new(
            required: mapped_enforced_claims
          )
        end

        def multiple_constraint
          @multiple_constraint ||= @multiple_constraint_class.new(*@constraints)
        end
      end
    end
  end
end
