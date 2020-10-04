# frozen_string_literal: true

# Utility class for processing WebSocket messages.
module Authentication
  module AuthnK8s
    class WebSocketMessage
      class << self
        def channel_byte(channel_name)
          channel_number_from_name(channel_name).chr
        end

        def channel_number_from_name(channel_name)
          channel_names.index(channel_name)
        end

        def channel_names
          %w(stdin stdout stderr error resize)
        end
      end

      # The "msg" argument comes from a websocket server and is assumed to
      # respond to "type" and "data" methods.
      def initialize(msg)
        @msg = msg
      end

      def type
        @msg.type
      end

      def data
        @msg.data[1..-1]
      end

      def channel_name
        self.class.channel_names[channel_number]
      end

      def channel_number
        unless @msg.respond_to?(:data)
          return self.class.channel_number_from_name('error')
        end

        @msg.data[0..0].bytes.first
      end
    end
  end
end
