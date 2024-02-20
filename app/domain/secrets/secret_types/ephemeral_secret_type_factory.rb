module Secrets
  module SecretTypes
    class EphemeralSecretTypeFactory
      def create_ephemeral_secret_type(type, type_params)
        if !type.nil? && type.casecmp("aws").zero?
          AWSEphemeralSecretTypeFactory.new.create_aws_ephemeral_secret_type(type_params)
        else
          raise ApplicationController::BadRequestWithBody, "Ephemeral Secret type is unsupported"
        end
      end
    end
  end
end