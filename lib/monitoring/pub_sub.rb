require 'singleton'
require 'active_support/notifications'

module Monitoring
  # PubSub and PubSubBase wrap ActiveSupport::Notifications, providing pub/sub
  # plumbing to custom controllers and collectors.
  class PubSub
    include Singleton

    def publish(name, payload = {})
      ActiveSupport::Notifications.instrument(name, payload)
    end

    def subscribe(name)
      ActiveSupport::Notifications.subscribe(name) do |_, _, _, _, payload|
        yield payload
      end
    end

    def unsubscribe(name)
      ActiveSupport::Notifications.unsubscribe(name)
    end
  end
end
