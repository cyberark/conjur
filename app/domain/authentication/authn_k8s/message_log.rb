module Authentication
  module AuthnK8s
    # Utility class for storing messages received during websocket communication.
    class MessageLog
      attr_reader :messages

      def initialize
        @messages = Hash.new { |hash, key| hash[key] = [] }
      end

      def save_message(wsmsg)
        channel_name = wsmsg.channel_name

        unless channel_name
          raise "Unexpected channel: #{wsmsg.channel_number}"
        end

        @messages[channel_name.to_sym] << wsmsg.data
      end

      def save_error_string(str)
        @messages[:error] << str
      end

    end
  end
end
