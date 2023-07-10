# frozen_string_literal: true

## This code is based on github.com/shokai/websocket-client-simple (MIT License)

require 'event_emitter'
require 'websocket'
require 'resolv'
require 'openssl'
require 'uri'

# Utility class for processing WebSocket messages.
#
# :reek:InstanceVariableAssumption for @frame and @handshake_finished.
# :reek:RepeatedConditional for secure? checks.
module Authentication
  module AuthnK8s
    class WebSocketClient
      include EventEmitter

      def self.connect(url, **options)
        client = WebSocketClient.new(url, **options)
        yield(client) if block_given?
        client.connect
        client
      end

      # Used by WebSocketClientEventHandler
      attr_reader :handshake

      def initialize(
        url,

        # Optional keyword arguments to configure the secure socket behavior
        hostname: nil,
        headers: nil,
        cert_store: SecureTcpSocket.default_cert_store,
        verify_mode: OpenSSL::SSL::VERIFY_PEER
      )
        # Parse the given url to ensure it's valid
        @uri = URI.parse(url)

        # Use the provided port or default to the standard ports
        @port = @uri.port || (secure? ? 443 : 80)

        @hostname = hostname
        @headers = headers
        @cert_store = cert_store
        @verify_mode = verify_mode
      end

      def connect
        # Do nothing if already connected
        return if @socket

        # Establish initial connection to server
        open_socket

        # If the connection uses TLS, establish the secure context
        secure_socket if secure?

        # Begin websocket IO loop in a separate thread
        begin_event_loop

        # Send initial websocket handshake
        @handshake ||= WebSocket::Handshake::Client.new(
          url: @uri.to_s,
          headers: @headers
        )
        @socket.write(@handshake.to_s)
      end

      def send(data, opt = { type: :text })
        return if !@handshake_finished || @closed

        type = opt[:type]
        frame = ::WebSocket::Frame::Outgoing::Client.new(
          data: data,
          type: type, version: @handshake.version
        )
        begin
          @socket.write(frame.to_s)
        rescue Errno::EPIPE => e
          @pipe_broken = true
          emit(:__close, e)
        end
      end

      def close
        return if @closed

        unless @pipe_broken
          send(nil, type: :close)
        end

        @closed = true
        @socket&.close
        @socket = nil

        emit(:__close)

        Thread.kill(@thread) if @thread
      end

      def open?
        @handshake.finished? && !@closed
      end

      protected

      # :reek:DuplicateMethodCall for @uri.host
      def open_socket
        @socket = if proxy_uri
          ProxiedTcpSocket.new(
            proxy_uri: proxy_uri,
            destination_host: @uri.host,
            destination_port: @port
          ).tcp_socket
        else
          TCPSocket.new(@uri.host, @port)
        end
      end

      # Wrap the given tcp_socket in an SSL socket to secure the connection
      def secure_socket
        @socket = SecureTcpSocket.new(
          socket: @socket,
          hostname: @hostname || @uri.host,
          cert_store: @cert_store,
          verify_mode: @verify_mode
        )
      end

      # This returns the proxy url relevant to the connection from the
      # environment. If the server connection uses TLS, then use the
      # https_proxy value, otherwise use the http_proxy value.
      def proxy_uri
        @proxy_uri ||= begin
          proxy_url = if secure?
            ENV['https_proxy'] || ENV['HTTPS_PROXY']
          else
            ENV['http_proxy'] || ENV['HTTP_PROXY']
          end

          URI.parse(proxy_url)
        rescue URI::InvalidURIError
          nil
        end
      end

      def secure?
        %w[https wss].include?(@uri.scheme)
      end

      # :reek:TooManyStatements
      def begin_event_loop
        @handshake_finished = false
        @pipe_broken = false
        @closed = false

        # Set up event handler with the websocket is closed
        once(:__close) do |err|
          close
          emit(:close, err)
        end

        @thread = Thread.new do
          until @closed
            begin
              unless recv_data = @socket.getc
                sleep(1)
                next
              end

              if @handshake_finished
                process_incoming_data(recv_data)
              else
                process_handshake_data(recv_data)
              end
            rescue => e
              emit(:error, e)
            end
          end
        end
      end

      def process_incoming_data(recv_data)
        # Initialize the frame if this is the first data received
        @frame ||= WebSocket::Frame::Incoming::Client.new

        # Add data to the frame and handle websocket events
        @frame << recv_data
        while msg = @frame.next
          emit(:message, msg)
        end
      end

      def process_handshake_data(recv_data)
        @handshake << recv_data

        # Continue waiting if the websocket handshake isn't finished
        return unless @handshake.finished?

        @handshake_finished = true
        emit(:open)
      end
    end
  end
end
