# frozen_string_literal: true

module DB
  module Service

    class SecretService < AbstractService

      def secret_value_change(secret_id, secret_value)
        db_secret = Secret.create(resource_id: secret_id, value: secret_value)
        notify_listeners(:secret, :"value.changed", db_secret)
      end

    end
  end
end

