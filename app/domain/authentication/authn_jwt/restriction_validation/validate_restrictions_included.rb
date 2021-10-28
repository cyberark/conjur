module Authentication
  module AuthnJwt
    module RestrictionValidation
      # This class is responsible for retrieving the correct value from the JWT token
      # of the requested attribute.
      class ValidateRestrictionsIncluded
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

          validate_annotation_value(restriction)

          unless @decoded_token.key?(claim_name)
            raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing,
                  claim_name_for_error(annotation_name, claim_name)
          end

          token_values = @decoded_token.fetch(claim_name)

          unless token_values.is_a?(Array)
            raise Errors::Authentication::ResourceRestrictions::InconsistentHostAnnotationType, annotation_name
          end

          parsed_annotation_values = parse_annotation_values(restriction)

          parsed_annotation_values.all? { |element| token_values.include?(element) }
        end

        private

        def validate_annotation_value(restriction)
          restriction_name = restriction.name
          if restriction.value.blank?
            raise Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven, restriction_name
          end

          unless parse_annotation_values(restriction).is_a?(Array)
            raise Errors::Authentication::ResourceRestrictions::InconsistentHostAnnotationType, restriction_name
          end
        end

        def claim_name(annotation_name)
          claim_name = @aliased_claims.fetch(annotation_name, annotation_name)
          @logger.debug(LogMessages::Authentication::AuthnJwt::ClaimMapUsage.new(annotation_name, claim_name)) unless annotation_name == claim_name
          claim_name
        end

        def parse_annotation_values(restriction)
          JSON.parse(restriction.value)
        rescue JSON::ParserError
          raise Errors::Authentication::ResourceRestrictions::InconsistentHostAnnotationType, restriction.name
        end

        def claim_name_for_error(annotation_name, claim_name)
          return annotation_name if annotation_name == claim_name

          "#{claim_name} (annotation: #{annotation_name})"
        end
      end
    end
  end
end
