require 'uri'

module Authentication
  module AuthnOidc
    module GetConjurOidcToken
      class LoginRequestBody
        attr_reader :redirect_uri, :authorization_code

        def initialize(request)
          decoded_request_body = decoded_body(request.body.read)

          @redirect_uri = decoded_request_body.assoc('redirect_uri').last
          @authorization_code = decoded_request_body.assoc('code').last
        end

        private

        def decoded_body(request_body)
          URI.decode_www_form(request_body)
        end
      end
    end
  end
end
