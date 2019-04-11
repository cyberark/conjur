# frozen_string_literal: true

module Test
  class AuditSink
    SOCKET_PATH="audit.sock"

    def initialize
      delete_socket

      begin
        @socket = UNIXServer.new SOCKET_PATH
      ensure
        at_exit { delete_socket }
      end

      @messages = []
      listen
    end

    def delete_socket
      @socket.close if @socket
      File.delete(SOCKET_PATH) if File.exist?(SOCKET_PATH)
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
