module Authentication
  module AuthnK8s
    # Utility class for storing messages received during websocket
    # communication.
    class MessageLog
      attr_reader :messages

      # Client code is responsible for calling this to validate messages before
      # saving them to a MessageLog instance. This separation allows validation
      # to be handled as needed, while keeping MessageLog a pure value object.
      class ValidateMessage
        def call(ws_msg)
          channel_name = ws_msg.channel_name
          return if channel_name

          raise Errors::Authentication::AuthnK8s::UnexpectedChannel,
                ws_msg.channel_number
        end
      end

      def initialize
        @messages = Hash.new { |hash, key| hash[key] = [] }
      end

      # "save_message" takes an argument of type WebSocketMessage. We assume the
      # caller has already validated the argument by calling
      # "MessageLog::ValidateMessage".
      def save_message(ws_msg)
        channel_name = ws_msg.channel_name
        @messages[channel_name.to_sym] << ws_msg.data
      end

      def save_error_string(str)
        @messages[:error] << str
      end

    end
  end
end
