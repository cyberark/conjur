module Authentication
  module AuthnJwt

    # This class is responsible for retrieving the correct value from the JWT token
    # of the requested attribute.
    class ValidateRestrictionsOneToOne
      def initialize(decoded_token:)
        @decoded_token = decoded_token
      end

      def valid_restriction?(restriction)
        unless @decoded_token.key?(restriction.name)
          raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing.new(restriction.name)
        end
        @decoded_token.fetch(restriction.name) == restriction.value
      end
    end
  end
end
