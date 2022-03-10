require 'singleton'
require 'active_support/notifications'

module Monitoring
  # PubSub and PubSubBase wrap ActiveSupport::Notifications, providing pub/sub
  # plumbing to custom controllers and collectors.

  class PubSubBase
    attr_reader :options

    def initialize(notifications = ActiveSupport::Notifications)
      @notifications = notifications
    end

    def publish(name, payload = {})
      @notifications.instrument(name, payload)
    end

    def subscribe(name)
      @notifications.subscribe(name) do |_, _, _, _, payload|
        yield payload
      end
    end

    def unsubscribe(name)
      @notifications.unsubscribe(name)
    end
  end

  class PubSub < PubSubBase
    include Singleton
  end
end
