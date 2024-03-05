module Secrets
  module SecretTypes
    class DynamicSecretTypeFactory
      def create_dynamic_secret_type(method)
        if !method.nil? && method.casecmp("federation-token").zero?
          Secrets::SecretTypes::AWSFederationTokenDynamicSecretType.new
        elsif !method.nil? && method.casecmp("assume-role").zero?
          Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType.new
        else
          raise ApplicationController::BadRequestWithBody, "Dynamic Secret method is unsupported"
        end
      end
    end
  end
end