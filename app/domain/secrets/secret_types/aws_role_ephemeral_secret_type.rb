module Secrets
  module SecretTypes
    class AWSRoleEphemeralSecretType < AWSEphemeralSecretType
      EPHEMERAL_ROLE_ARN = "ephemeral/role-arn"

      def input_validation(type_params)
        super(type_params)

        if type_params[:method_params].nil?
          raise Errors::Conjur::ParameterMissing.new("method_params")
        end

        data_fields = {
          role_arn: String
        }
        method_params = type_params[:method_params]
        validate_required_data(method_params, data_fields.keys)
        validate_data(method_params, data_fields)
      end
    end
  end
end