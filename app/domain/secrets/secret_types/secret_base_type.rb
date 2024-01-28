module Secrets
  module SecretTypes
    class SecretBaseType
      def create_variable(resource_id, owner)
        ::Resource.create(resource_id: resource_id, owner_id: owner[:role_id], policy_id: owner[:role_id])
      end
    end
  end
end
