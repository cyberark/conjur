# frozen_string_literal: true

module Test
  class AuditSink
    def initialize
      delete_socket

      begin
        $stderr.puts("Creating socket: #{socket_path}")
        @socket = UNIXServer.new(socket_path)
      ensure
        at_exit { delete_socket }
      end

      @messages = []
      listen
    end

    def delete_socket
      @socket&.close
      File.delete(socket_path) if File.exist?(socket_path)
    end

    def listen backlog = 1
      socket.listen(backlog)
      Thread.new { loop { handle(socket.accept) } }
        .abort_on_exception = true # to ease debugging
    end

    def handle sock
      sock.each_line(&messages.method(:push))
    end

    def address
      socket.addr[1]
    end

    def socket_path
      @socket_path ||= File.join(
        Dir.tmpdir,
        "audit_test_#{Process.pid}_#{Thread.current.object_id}.sock"
      )
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
