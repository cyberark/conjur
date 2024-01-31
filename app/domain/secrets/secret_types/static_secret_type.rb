module Secrets
  module SecretTypes
    class StaticSecretType  < SecretBaseType
      include ParamsValidator

      def input_validation(params)
        data_fields = {
          mime_type: String
        }
        validate_data(params, data_fields)
      end

      def set_value(variable_resource, value)
        unless value.nil? || value.empty?
          Secret.create(resource_id: variable_resource.id, value: value)
          variable_resource.enforce_secrets_version_limit
        end
      end
    end
  end
end