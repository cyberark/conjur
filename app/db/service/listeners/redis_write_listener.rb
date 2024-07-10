# frozen_string_literal: true
module DB
  module Service
    module Listeners
      class RedisWriteListener < AbstractWriteListener
        include ::Secrets::RedisHandler
        def notify(entity, operation, db_obj)
          case [entity, operation]
          when [:secret, :"value.changed"]
            # Delete and not update to avoid corner case where commit to DB fails
            delete_redis_secret(db_obj.resource_id)
          end
        end
      end
    end
  end
end
