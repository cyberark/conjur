module Authentication
  module AuthnGcp

    # This class is responsible for retrieving the correct value from the GCP token
    # of the requested attribute.
    class AuthenticationRequest
      def initialize(decoded_token:)
        @decoded_token = decoded_token
      end

      def valid_restriction?(restriction)
        token_value =
          case restriction.name
          when Restrictions::PROJECT_ID
            @decoded_token.project_id
          when Restrictions::INSTANCE_NAME
            @decoded_token.instance_name
          when Restrictions::SERVICE_ACCOUNT_ID
            @decoded_token.service_account_id
          when Restrictions::SERVICE_ACCOUNT_EMAIL
            @decoded_token.service_account_email
          end

        raise Errors::Authentication::AuthnGcp::JwtTokenClaimIsMissing, restriction.name if token_value.blank?

        token_value == restriction.value
      end
    end
  end
end
