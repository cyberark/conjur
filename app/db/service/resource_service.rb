# frozen_string_literal: true

module DB
  module Service

    class ResourceService < AbstractService
      include ::Secrets::RedisHandler

      # Creates a new resource and handles specific resource types. Returns nil if creation fails.
      # Currently only variable resource type is handled.
      def create_resource(resource_id, owner_id, policy_id)
        resource = Resource.create(resource_id: resource_id, owner_id: owner_id, policy_id: policy_id)
        if resource.nil?
          @logger.error("Resource creation failed for resource_id: #{resource_id} owner_id: #{owner_id} policy_id: #{policy_id}")
          return nil
        end
        handler = self.class.resource_handlers[resource.kind]
        handler.create(resource) if handler
        resource
      end

      # In policy controller if resource is not found, it will not raise error.
      # So the function will return nil if it was not found in the DB, for other to handle it as they see fit.
      def delete_resource(resource_id)
        resource = ::Resource[resource_id]
        if resource
          resource.destroy
          handler = self.class.resource_handlers[resource.kind]
          handler.delete(resource) if handler
        end
        resource
      end

      def self.resource_handlers
        {
          'host' => ::DB::Service::Types::WorkloadType.instance,
          'user' => ::DB::Service::Types::UserType.instance,
          'variable' => ::DB::Service::Types::VariableType.instance
        }
      end

    end
  end
end

