module Secrets
  module SecretTypes
    class AWSEphemeralSecretTypeFactory
      def create_aws_ephemeral_secret_type(type_params)
        if !type_params.nil? && !type_params[:method].nil? && type_params[:method].casecmp("federation-token").zero?
          Secrets::SecretTypes::AWSEFederationTokenEphemeralSecretType.new
        elsif !type_params.nil? && !type_params[:method].nil? && type_params[:method].casecmp("assume-role").zero?
          Secrets::SecretTypes::AWSRoleEphemeralSecretType.new
        else
          raise ApplicationController::BadRequestWithBody, "Ephemeral Secret aws method is unsupported"
        end
      end
    end
  end
end