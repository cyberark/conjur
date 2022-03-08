module Monitoring
    # Module PubSub wraps ActiveSupport::Notifications, providing PubSub
    # plumbing to custom Controllers or Collectors.
    module PubSub

    extend self

    def publish(name, payload = {}, &block)
      ActiveSupport::Notifications.instrument(name, payload, &block)
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
