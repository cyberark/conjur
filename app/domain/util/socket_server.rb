require 'timeout'
require 'fileutils'
require 'socket'

module Util
  class SocketService
    def initialize(socket:, queue_length: 5, timeout: 1, logger: Logger.new($stderr, level: Logger::INFO))
      @socket = socket
      @queue_length = queue_length
      @timeout = timeout
      @logger = logger

      validate_filesystem_assumptions(socket_file: socket)
    end

    def validate_filesystem_assumptions(socket_file:)
      if File.exist?(socket_file)
        raise "Socket: #{socket_file} already exists"
      end

      socket_dir = File.dirname(socket_file)

      return if File.directory?(socket_dir)

      raise("Socket Service requires directory #{socket_dir.inspect} to exist and be a directory")
    end

    def cleanup
      # remove the socket on exit
      # !! Note !!: A logger isn't allowed in a `trap` block, so we need
      # to provide an IO.pipe to write the exit message to.
      $stderr.puts("Removing socket #{@socket}")
      File.unlink(@socket)
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
    #
    # !! Note: the response is transformed into JSON to be sent through the socket.
    def run(&block)
      server = UNIXServer.new(@socket)
      trap(0) { cleanup }

      server.listen(@queue_length)
      @logger.info("service is listening at #{@socket}")

      loop do
        connection = server.accept
        begin
          Timeout.timeout(@timeout) do
            arguments = connection.gets.strip
            begin
              @logger.debug("arguments: #{arguments.inspect}")
              response = connection.puts(block.call(arguments).to_json)
              @logger.debug("response: #{response.inspect}")
              response
            rescue
              @logger.error("Error in service '#{@socket}': #{$ERROR_INFO}")
              connection.puts
            ensure
              connection.close
            end
          end
        rescue Timeout::Error
          @logger.error("Timeout::Error in service '#{@socket}'")
        end
      end
    end
  end
end
