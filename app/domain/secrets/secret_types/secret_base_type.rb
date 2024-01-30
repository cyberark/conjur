module Secrets
  module SecretTypes
    class SecretBaseType
      def create_variable(resource_id, owner)
        ::Resource.create(resource_id: resource_id, owner_id: owner[:role_id], policy_id: owner[:role_id])
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", resource_id)
      end

      def set_value(variable_resource, value)
        #No implementation
      end
    end
  end
end
