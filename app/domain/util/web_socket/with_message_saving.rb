module Util
  module WebSocket
    class WithMessageSaving < SimpleDelegator
      attr_reader :messages
      
      def initialize(ws)
        super(ws)
        @messages = Hash.new { |hash,key| hash[key] = [] }
      end

      def save_message(msg, stream: nil)
        strm ||= stream(msg)
        raise "Unexpected channel: #{channel(msg)}" unless strm
        @messages[strm.to_sym] << msg
      end

      def stream(msg)
        stream_name(channel_from_message(msg))
      end

      def msg_data(msg)
        msg.data[1..-1]
      end

      # NOTE: yes, a hash would be more efficient, but it doesn't matter
      #
      def channel(stream_name)
        stream_names.index(stream_name)
      end

      def stream_name(channel)
        stream_names[channel]
      end

      private

      def channel_from_message(msg)
        # THIS LINE WAS THE FIX
        return channel('error') unless msg.respond_to?(:data)
        msg.data[0..0].bytes.first
      end

      def stream_names
        %[stdin stdout stderr error resize]
      end
    end
  end
end
