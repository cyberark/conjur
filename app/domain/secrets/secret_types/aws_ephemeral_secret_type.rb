module Secrets
  module SecretTypes
    class AWSEphemeralSecretType  < EphemeralSecretType
      EPHEMERAL_VARIABLE_METHOD = "ephemeral/method"
      EPHEMERAL_REGION = "ephemeral/region"
      EPHEMERAL_POLICY = "ephemeral/inline-policy"

      def input_validation(type_params)
        data_fields = {
          region: String
        }
        validate_required_data(type_params, data_fields.keys)
        validate_data(type_params, data_fields)
      end
    end
  end
end
