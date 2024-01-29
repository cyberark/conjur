module Secrets
  module SecretTypes
    class SecretBaseType
      include ParamsValidator

      def create_variable(resource_id, owner)
        ::Resource.create(resource_id: resource_id, owner_id: owner[:role_id], policy_id: owner[:role_id])
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", resource_id)
      end

      def input_validation(secret_name)
        # Validate the name of the secret is correct
        validate_name(secret_name)


      end
    end
  end
end
