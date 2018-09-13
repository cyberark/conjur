module Util
  module WebSocket
    class StreamState
      def initialize
        @closed = false
      end

      def close
        @closed = true
      end

      def closed?
        @closed
      end
    end
  end
end
