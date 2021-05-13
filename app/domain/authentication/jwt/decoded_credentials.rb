module Authentication
  module Jwt

    class DecodedCredentials

      JWT_REQUEST_BODY_FIELD_NAME = "jwt".freeze
      # https://datatracker.ietf.org/doc/html/rfc4648#section-5
      # jwt token is 3 blocks of base64url encoded strings separated by period '.'
      # base64url encoding differs from regular base64 encoding as follows
      # - padding is skipped so the pad character '=' doesn't have to be percent encoded
      # - the 62nd and 63rd regular base64 encoding characters ('+' and '/') are replace with ('-' and '_')
      #   The changes make the encoding alphabet file and URL safe.
      # tokens without a signature part are denied
      BASE_64_URL_REGEX = "[-A-Za-z0-9_=]+".freeze
      JWT_REGEX = /\A#{BASE_64_URL_REGEX}\.#{BASE_64_URL_REGEX}\.#{BASE_64_URL_REGEX}\z/.freeze

      def initialize(credentials)
        @decoded_credentials = Hash[URI.decode_www_form(credentials)]
        validate_jwt_request_field_is_present
        extract_token
        validate_jwt_format
      end

      def jwt
        @jwt
      end

      private

      def validate_jwt_request_field_is_present
        if @decoded_credentials.fetch(JWT_REQUEST_BODY_FIELD_NAME, "") == ""
          raise Errors::Authentication::RequestBody::MissingRequestParam, JWT_REQUEST_BODY_FIELD_NAME
        end
      end

      def extract_token
        @jwt ||= @decoded_credentials[JWT_REQUEST_BODY_FIELD_NAME].strip
      end

      def validate_jwt_format
        raise Errors::Authentication::Jwt::RequestBodyIsNotJWTToken unless is_jwt?
      end

      def is_jwt?
        @jwt =~ JWT_REGEX
      end

    end
  end
end
