module DB
  module Service
    module Types
      class WorkloadType < ResourceType
        include ::Secrets::RedisHandler

        def create(resource)
          # TODO Implement workload creation
        end

        def delete(resource)
          delete_redis_user(resource.id)
        end
      end
    end
  end
end