module Authentication
  module AuthnJwt
    module RestrictionValidation
      # This class is responsible for retrieving the correct value from the JWT token
      # of the requested attribute.
      class ValidateRestrictionsOneToOne
        def initialize(
          decoded_token:,
          aliased_claims:,
          logger: Rails.logger
        )
          @decoded_token = decoded_token
          @aliased_claims = aliased_claims
          @logger = logger
        end

        def valid_restriction?(restriction)
          annotation_name = restriction.name
          claim_name = claim_name(annotation_name)
          restriction_value = restriction.value

          if restriction_value.blank?
            raise Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven, annotation_name
          end

          unless @decoded_token.key?(claim_name)
            raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing,
                  claim_name_for_error(annotation_name, claim_name)
          end

          @decoded_token.fetch(claim_name) == restriction_value
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
      end
    end
  end
end
