module DB
  module Service
    module Types
      class UserType < ResourceType
        include ::Secrets::RedisHandler

        def create(resource)
          # TODO: Implement user creation
        end

        def delete(resource)
          delete_redis_user(resource.id)
        end
      end
    end
  end
end