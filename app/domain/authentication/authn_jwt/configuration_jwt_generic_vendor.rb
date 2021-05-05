module Authentication
  module AuthnJwt
    # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
    class ConfigurationJWTGenericVendor < ConfigurationInterface
      def self.jwt_identity(authentication_parameters)
        id_provider = Authentication::AuthnJwt::IdentityProviderFactory.new(authentication_parameters).relevant_id_provider
        id_provider.provide_jwt_identity
      end

      def self.validate_restrictions(authentication_parameters)
        true
      end

      def self.validate_and_decode_token(authentication_parameters)
        # Dummy decoded jwt token. Will be replaced on implementation
        {
          "namespace_id": "1",
          "namespace_path": "root",
          "project_id": "34",
          "project_path": "root/test-proj",
          "user_id": "1",
          "user_login": "cucumber",
          "user_email": "admin@example.com",
          "pipeline_id": "1",
          "job_id": "4",
          "ref": "master",
          "ref_type": "branch",
          "ref_protected": "true",
          "jti": "90c4414b-f7cf-4b98-9a4f-2c29f360e6d0",
          "iss": "ec2-18-157-123-113.eu-central-1.compute.amazonaws.com",
          "iat": 1619352275,
          "nbf": 1619352270,
          "exp": 1619355875,
          "sub": "job_4"
        }
      end
    end
  end
end
