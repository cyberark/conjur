module Secrets
  module SecretTypes
    class DynamicSecretTypeFactory
      def create_dynamic_secret_type(method)
        if !method.nil? && method.casecmp(AwsIssuerType::FEDERATION_TOKEN_METHOD).zero?
          Secrets::SecretTypes::AWSFederationTokenDynamicSecretType.new
        elsif !method.nil? && method.casecmp(AwsIssuerType::ASSUME_ROLE_METHOD).zero?
          Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType.new
        else
          raise ApplicationController::BadRequestWithBody, "Dynamic Secret method is unsupported"
        end
      end
    end
  end
end