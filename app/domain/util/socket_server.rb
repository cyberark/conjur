require 'timeout'
require 'fileutils'
require 'socket'

module Util
  class SocketService
    def initialize(socket:, queue_length: 5, timeout: 1, message_writer: $stderr)
      @socket = socket
      @queue_length = queue_length
      @timeout = timeout
      @message_writer = message_writer

      socket_dir = File.dirname(socket)

      return if File.directory?(socket_dir)

      raise("Socket Service requires directory #{socket_dir.inspect} to exist and be a directory")
    end

    # Accepts a block for the desired response behavior.
    # The message passed to the socket is available as a string
    # inside the block as a block attribute. Ex:
    #
    #   Util::SocketService.new(socket: '/socket/path').run do |passed_arguments|
    #     Authentication::AuthnOidc::V2::Commands::ListProviders.new.call(
    #       message: passed_arguments
    #     )
    #   end
    def run(&block)
      raise "Socket: #{@socket} already exists" if File.exist?(@socket)

      server = UNIXServer.new(@socket)

      trap(0) do
        # remove the socket on exit
        @message_writer.puts("Removing socket #{@socket}")
        File.unlink(@socket)
      end

      server.listen(@queue_length)

      @message_writer.puts("service is listening at #{@socket}")

      while connection = server.accept
        begin
          Timeout.timeout(@timeout) do
            arguments = connection.gets.strip
            begin
              connection.puts(block.call(arguments))
            rescue
              @message_writer.puts("Error in service '#{@socket}': #{$!}")
              connection.puts
            ensure
              connection.close
            end
          end
        rescue Timeout::Error
          @message_writer.puts("Timeout::Error in service '#{@socket}'")
        end
      end
    end
  end
end
