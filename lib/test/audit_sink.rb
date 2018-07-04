# frozen_string_literal: true

module Test
  class AuditSink
    def initialize
      @socket = UNIXServer.new ''
      @messages = []
      listen
    end

    def listen backlog = 1
      socket.listen backlog
      Thread.new { loop { handle socket.accept } }
        .abort_on_exception = true # to ease debugging
    end

    def handle sock
      sock.each_line(&messages.method(:push))
    end

    def address
      socket.addr[1]
    end

    attr_reader :socket, :messages

    class << self
      def instance
        @instance ||= new
      end
      
      extend Forwardable
      def_delegators :instance, :messages
    end
  end
end
