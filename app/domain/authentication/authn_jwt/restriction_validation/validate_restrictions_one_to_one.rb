module Authentication
  module AuthnJwt
    module RestrictionValidation
      # This class is responsible for retrieving the correct value from the JWT token
      # of the requested attribute.
      class ValidateRestrictionsOneToOne
        def initialize(
          decoded_token:,
          aliased_claims:,
          parse_claim_path: Authentication::AuthnJwt::ParseClaimPath.new,
          logger: Rails.logger
        )
          @decoded_token = decoded_token
          @aliased_claims = aliased_claims
          @parse_claim_path = parse_claim_path
          @logger = logger
        end

        def valid_restriction?(restriction)
          annotation_name = restriction.name
          claim_name = claim_name(annotation_name)
          restriction_value = restriction.value

          if restriction_value.blank?
            raise Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven, annotation_name
          end

          # Parsing the claim path means claims with slashes are interpreted
          # as nested claims - for example 'a/b/c' corresponds to the doubly-
          # nested claim: {"a":{"b":{"c":"value"}}}.
          #
          # We should also support claims that contain slashes as namespace
          # indicators, such as 'namespace.com/claim', which would correspond
          # to the top-level claim: {"namespace.com/claim":"value"}.
          claim_value = @decoded_token[claim_name]
          claim_value ||= @decoded_token.dig(*parsed_claim_path(claim_name))
          if claim_value.nil?
            raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing,
                  claim_name_for_error(annotation_name, claim_name)
          end

          restriction_value == claim_value
        end

        private

        def claim_name(annotation_name)
          claim_name = @aliased_claims.fetch(annotation_name, annotation_name)
          @logger.debug(LogMessages::Authentication::AuthnJwt::ClaimMapUsage.new(annotation_name, claim_name)) unless
            annotation_name == claim_name
          claim_name
        end

        def claim_name_for_error(annotation_name, claim_name)
          return annotation_name if annotation_name == claim_name

          "#{claim_name} (annotation: #{annotation_name})"
        end

        def parsed_claim_path(claim_path)
          @parse_claim_path.call(claim: claim_path)
        end
      end
    end
  end
end
