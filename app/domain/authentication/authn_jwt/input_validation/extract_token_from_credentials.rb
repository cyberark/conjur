module Authentication
  module AuthnJwt
    module InputValidation
      ExtractTokenFromCredentials ||= CommandClass.new(
        dependencies: {
          decoded_credentials_class: Authentication::Jwt::DecodedCredentials
        },
        inputs: %i[credentials]
      ) do
        def call
          decode_credentials
          extract_token_from_credentials
        end

        private

        def decode_credentials
          decoded_credentials
        end

        def decoded_credentials
          @decoded_credentials ||= @decoded_credentials_class.new(@credentials)
        end

        def extract_token_from_credentials
          decoded_credentials.jwt
        end
      end
    end
  end
end
