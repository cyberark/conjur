# frozen_string_literal: true

module DB
  module Service

    class ResourceService < AbstractService
      include ::Secrets::RedisHandler

      def create_resource(resource_id, owner_id, policy_id)
        resource = Resource.create(resource_id: resource_id, owner_id: owner_id, policy_id: policy_id)
        if resource.nil?
          Rails.logger.error("Resource creation failed for resource_id: #{resource_id} owner_id: #{owner_id} policy_id: #{policy_id}")
        end
        if resource.kind == 'variable'
          ::DB::Service::Types::VariableType.instance.create(resource)
        end
        return resource
      end

      # In policy controller if resource is not found, it will not raise error.
      # So the function will return nil if it was not found in the DB, for other to handle it as they see fit.
      def delete_resource(resource_id)
        resource = ::Resource[resource_id]
        if resource
          resource.destroy
          ## remove role (user or host)
          delete_redis_user(resource.id) if resource.kind == 'user' || resource.kind == 'host'
           if resource.kind == 'variable'
             ::DB::Service::Types::VariableType.instance.delete(resource)
           end
        end
        return resource
      end

    end
  end
end

