require 'command_class'

# This class validates that request body contains JWT encoded token
module Authentication
  module AuthnJwt

    JWTValidateRequestBody ||= CommandClass.new(
      dependencies: {
      },
      inputs: %i[body_string]
    ) do

      def call
        validate_body
      end

      private

      def validate_body
        raise Errors::Authentication::Jwt::RequestBodyIsNotJWTToken unless @body_string =~ jwt_regex
      end

      def jwt_regex
        # https://datatracker.ietf.org/doc/html/rfc4648#section-5
        # jwt token is 3 blocks of base64url encoded strings separated by period '.'
        # base64url encoding differs from regular base64 encoding as follows
        # - padding is skipped so the pad character '=' doesn't have to be percent encoded
        # - the 62nd and 63rd regular base64 encoding characters ('+' and '/') are replace with ('-' and '_')
        #   The changes make the encoding alphabet file and URL safe.
        # tokens without a signature part are denied
        /\A[A-Za-z0-9\-_=]+\.[A-Za-z0-9\-_=]+\.[A-Za-z0-9\-_=]+\z/
      end

    end
  end
end
