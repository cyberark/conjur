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
        decoded_request_body = decoded_body(request_body)
        id_token = decoded_request_body.assoc('id_token').last
        JSON.parse(id_token)
      end
    end
  end
end
