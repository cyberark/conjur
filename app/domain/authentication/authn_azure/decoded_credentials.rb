module Authentication
  module AuthnAzure

    class DecodedCredentials

      JWT_REQUEST_BODY_FIELD_NAME = "jwt".freeze

      def initialize(credentials)
        @decoded_credentials = Hash[URI.decode_www_form(credentials)]
        validate
      end

      def jwt
        @decoded_credentials[JWT_REQUEST_BODY_FIELD_NAME]
      end

      private

      def validate
        unless @decoded_credentials.include?(JWT_REQUEST_BODY_FIELD_NAME) &&
            !@decoded_credentials[JWT_REQUEST_BODY_FIELD_NAME].empty?
          raise Errors::Authentication::RequestBody::MissingRequestParam, JWT_REQUEST_BODY_FIELD_NAME
        end
      end
    end
  end
end
