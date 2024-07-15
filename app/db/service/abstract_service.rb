# frozen_string_literal: true
require 'singleton'

module DB
  module Service
    class AbstractService
      include Singleton

      protected
      def notify_listeners(entity, operation, db_object)
        listeners.each do |listener|
          listener.notify(entity, operation, db_object)
        end
      end

      private
      def listeners
        [Listeners::RedisWriteListener.instance, Listeners::EventWriteListener.instance]
      end

    end
  end
end