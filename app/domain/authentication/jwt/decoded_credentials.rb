module Authentication
  module Jwt

    class DecodedCredentials

      JWT_REQUEST_BODY_FIELD_NAME = "jwt".freeze

      def initialize(credentials)
        @logger = Rails.logger
        @decoded_credentials = Hash[URI.decode_www_form(credentials)]
        validate_jwt_request_field_is_present
        validate_body_contains_jwt
      end

      def jwt
        @jwt_token
      end

      private

      def validate_jwt_request_field_is_present
        if @decoded_credentials.fetch(JWT_REQUEST_BODY_FIELD_NAME, "") == ""
          raise Errors::Authentication::RequestBody::MissingRequestParam, JWT_REQUEST_BODY_FIELD_NAME
        end
        @jwt_token = @decoded_credentials[JWT_REQUEST_BODY_FIELD_NAME].strip
      end

      def validate_body_contains_jwt
        raise Errors::Authentication::Jwt::RequestBodyIsNotJWTToken unless is_jwt?
      end

      def is_jwt?
        @jwt_token =~ jwt_regex
      end

      def jwt_regex
        # https://datatracker.ietf.org/doc/html/rfc4648#section-5
        # jwt token is 3 blocks of base64url encoded strings separated by period '.'
        # base64url encoding differs from regular base64 encoding as follows
        # - padding is skipped so the pad character '=' doesn't have to be percent encoded
        # - the 62nd and 63rd regular base64 encoding characters ('+' and '/') are replace with ('-' and '_')
        #   The changes make the encoding alphabet file and URL safe.
        # tokens without a signature part are denied
        /\A[-A-Za-z0-9_=]+\.[-A-Za-z0-9_=]+\.[-A-Za-z0-9_=]+\z/
      end

    end
  end
end
