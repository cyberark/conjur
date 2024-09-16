# frozen_string_literal: true
module DB
  module Service
    module Types
      class VariableType < ResourceType
        include ::Secrets::RedisHandler
        def create(resource)
          ::SecretEventInput.instance.send_event(::SecretEventInput::CREATE, resource)
        end

        def delete(resource)
          ## remove secret
          delete_redis_secret(resource.id)
          ## remove resource_id for variable in show endpoint
          delete_redis_resource(resource.id)
          ## write pubsub event of deletion of secret
          ::SecretEventInput.instance.send_event(::SecretEventInput::DELETE, resource)
        end

      end

    end
  end
end