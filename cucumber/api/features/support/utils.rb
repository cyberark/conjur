# frozen_string_literal: true

# Miscellaneous utility functions for cucumber tests
module Utils
  class << self
    # Runs a webrick for the app in a thread on an ephemeral port.
    # Returns the URI to it.
    # Note the server will automatically shutdown when the test run is finished.
    # Also note that since this is a ruby thread it will sleep when GIL is taken.
    # This means it might be inconvenient to use eg. when interactively debugging.
    def start_local_server addr = 'localhost'
      port = find_ephemeral_port(addr)
      Thread.new do
        Rack::Server.start(\
          config: File.expand_path('../../../../config.ru', __dir__),
          server: :webrick,
          Port: port
        )
      end
      @local_conjur_server = "http://#{addr}:#{port}"
    end

    attr_reader :local_conjur_server

    def find_ephemeral_port addr = 'localhost'
      TCPServer.open(addr, 0) { |server| server.addr[1] }
    end
  end
end
