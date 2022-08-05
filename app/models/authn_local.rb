# frozen_string_literal: true

AuthnLocal = Struct.new(:socket, :queue_length, :timeout) do
  class << self
    def run socket:, queue_length:, timeout:
      socket ||= '/run/authn-local/.socket'
      socket_dir = File.dirname(socket)

      unless File.directory?(socket_dir)
        $stderr.puts("authn-local requires directory #{socket_dir.inspect} to exist and be a directory")
        $stderr.puts("authn-local will not be enabled")
        return
      end

      queue_length ||= 5
      queue_length = queue_length.to_i

      timeout ||= 1
      timeout = timeout.to_i

      Util::SocketService.new(
        socket: socket,
        queue_length: queue_length,
        timeout: timeout
      ).run do |passed_arguments|
        Commands::Authentication::IssueToken.new.call(
          message: passed_arguments
        )
      end
    end
  end
end
