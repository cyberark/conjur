module Authentication
  module AuthnJwt
    module RestrictionValidators
      # This class is responsible for retrieving the correct value from the JWT token
      # of the requested attribute.
      class ValidateRestrictionsOneToOne
        def initialize(decoded_token:)
          @decoded_token = decoded_token
        end

        def valid_restriction?(restriction)
          restriction_name = restriction.name
          restriction_value = restriction.value
          if restriction_value.blank?
            raise Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven, restriction_name
          end
          unless @decoded_token.key?(restriction_name)
            raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing, restriction_name
          end

          @decoded_token.fetch(restriction_name) == restriction_value
        end
      end
    end
  end
end
