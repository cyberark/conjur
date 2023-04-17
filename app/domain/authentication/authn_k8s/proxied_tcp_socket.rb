# frozen_string_literal: true

require 'delegate'
require 'socket'

module Authentication
  module AuthnK8s
    # A proxy socket first establishes a TCP connection through a configured
    # proxy server
    #
    # :reek:TooManyInstanceVariables
    # :reek:InstanceVariableAssumption for @proxy_socket
    class ProxiedTcpSocket < SimpleDelegator
      attr_reader :tcp_socket

      def initialize(
        proxy_uri:,
        destination_host:,
        destination_port:,
        timeout: 60, # seconds

        # Injected dependencies
        logger: Rails.logger
      )
        @proxy_uri = proxy_uri
        @destination_host = destination_host
        @destination_port = destination_port
        @timeout = timeout
        @logger = logger

        @tcp_socket = connect_proxy_socket

        # Connect to the proxy
        super(@tcp_socket)
      end

      protected

      def connect_proxy_socket
        # We log the proxy host and port specifically because the full URI may
        # contain authorization fields.
        @logger.debug(
          "Connecting to '#{@destination_host}:#{@destination_port}' " \
          "through proxy server: '#{@proxy_uri.host}:#{@proxy_uri.port}'"
        )

        @proxy_socket = TCPSocket.new(
          @proxy_uri.host,
          @proxy_uri.port,
          connect_timeout: @timeout
        )

        # Send proxy connection handshake
        @proxy_socket.write(proxy_connect_string)

        # This will block until the response is received. It raises an
        # exception if the proxy response is not received or is invalid.
        wait_for_proxy_response

        @proxy_socket
      end

      # :reek:DuplicateMethodCall for @proxy_uri methods
      def wait_for_proxy_response
        # Set the deadline time for the socket response.
        deadline = Time.now + @timeout

        # Loop until the expected string is received or the deadline is reached.
        response = ''
        while !response.include?("\r\n\r\n") && Time.now < deadline
          # Calculate the remaining time until the deadline.
          remaining_time = deadline - Time.now

          # Wait until the socket is ready to be read, or until the
          # deadline is reached.
          ready = IO.select([@proxy_socket], nil, nil, remaining_time)

          unless ready
            # The deadline has been reached without receiving the
            # expected string
            raise "Timed out waiting for the proxy " \
                  "('#{@proxy_uri.host}:#{@proxy_uri.port}') to respond. " \
                  "Received: '#{response.strip}'"
          end

          # Read from the socket and append to the response string
          response += @proxy_socket.read(1)
        end

        # Verify we received a valid connection response
        return if response.downcase.include?('200 connection established')

        # If we didn't receive the expected response, raise an error
        raise "Proxy ('#{@proxy_uri.host}:#{@proxy_uri.port}') returned an " \
              "invalid response: '#{response.strip}'"
      end

      # For spec details, see:
      # https://httpwg.org/specs/rfc9110.html#CONNECT
      def proxy_connect_string
        connect_string = \
          "CONNECT #{@destination_host}:#{@destination_port} HTTP/1.1\r\n" \
          "Host: #{@destination_host}\r\n"

        if proxy_authorization
          connect_string += \
            "Proxy-Authorization: Basic #{proxy_authorization}\r\n"
        end

        connect_string + "\r\n"
      end

      # :reek:DuplicateMethodCall because of accessing #user and #password twice
      def proxy_authorization
        return unless @proxy_uri.user && @proxy_uri.password

        Base64.strict_encode64("#{@proxy_uri.user}:#{@proxy_uri.password}")
      end
    end
  end
end
