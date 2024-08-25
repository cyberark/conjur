# frozen_string_literal: true

module DB
  module Service

    class SecretService < AbstractService
      include ::Secrets::RedisHandler

      def secret_value_change(secret_id, secret_value)
        db_secret = Secret.create(resource_id: secret_id, value: secret_value)
        # Enforce version number
        db_secret.enforce_secrets_version_limit
        # Redis
        delete_redis_secret(db_secret.resource_id) #Delete and not update to avoid corner case where commit to DB fails
        # Send event
        ::SecretEventInput.instance.send_event(::SecretEventInput::CHANGE, db_secret)
      end

    end
  end
end

