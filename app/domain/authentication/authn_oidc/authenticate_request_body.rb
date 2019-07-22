require 'uri'
require 'json'

module Authentication
  module AuthnOidc
    class AuthenticateRequestBody
      attr_reader :id_token

      def initialize(request)
        @id_token = parsed_id_token(request.body.read)
      end

      private

      def decoded_body(request_body)
        URI.decode_www_form(request_body)
      end

      def parsed_id_token(request_body)
        id_token_field = "id_token"

        decoded_id_token_key_value = decoded_body(request_body).assoc(id_token_field)

        # check that id token field exists and has some value
        raise Errors::Authentication::RequestBody::MissingRequestParam, id_token_field if decoded_id_token_key_value.nil? ||
            !decoded_id_token_key_value.include?(id_token_field) ||
            !decoded_id_token_key_value.last.present?

        # return the value of the id token
        decoded_id_token_key_value.last
      end
    end
  end
end
