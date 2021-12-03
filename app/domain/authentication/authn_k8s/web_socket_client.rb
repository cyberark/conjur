## This code is based on github.com/shokai/websocket-client-simple (MIT License)

require "event_emitter"
require 'websocket'

# Utility class for processing WebSocket messages.
module Authentication
  module AuthnK8s
    class WebSocketClient
      include EventEmitter
      attr_reader :url, :handshake

      def self.connect(url, options = {})
        client = WebSocketClient.new
        yield(client) if block_given?
        client.connect(url, options)
        client
      end

      def connect(url, options = {})
        return if @socket

        @url = url
        uri = URI.parse(url)
        @socket = TCPSocket.new(uri.host,
                                uri.port || (uri.scheme == 'wss' ? 443 : 80))
        if %w[https wss].include?(uri.scheme)
          ctx = OpenSSL::SSL::SSLContext.new
          ssl_version = options[:ssl_version] || 'SSLv23'
          ctx.ssl_version = ssl_version
          ctx.verify_mode = options[:verify_mode] || OpenSSL::SSL::VERIFY_NONE # use VERIFY_PEER for verification
          cert_store = options[:cert_store]
          unless cert_store
            cert_store = OpenSSL::X509::Store.new
            cert_store.set_default_paths
          end
          ctx.cert_store = cert_store

          @socket = ::OpenSSL::SSL::SSLSocket.new(@socket, ctx)
          if ssl_version != 'SSLv23'
            @socket.hostname = options[:hostname] || uri.host
          end
          @socket.connect
          @socket.post_connection_check(@socket.hostname) if @socket.hostname
        end
        @handshake = ::WebSocket::Handshake::Client.new(url: url, headers: options[:headers])
        @handshaked = false
        @pipe_broken = false
        frame = ::WebSocket::Frame::Incoming::Client.new
        @closed = false
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
              if @handshaked
                frame << recv_data
                while msg = frame.next
                  emit(:message, msg)
                end
              else
                @handshake << recv_data
                if @handshake.finished?
                  @handshaked = true
                  emit(:open)
                end
              end
            rescue => e
              emit(:error, e)
            end
          end
        end

        @socket.write(@handshake.to_s)
      end

      def send(data, opt = { type: :text })
        return if !@handshaked || @closed

        type = opt[:type]
        frame = ::WebSocket::Frame::Outgoing::Client.new(data: data, type: type, version: @handshake.version)
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

    end
  end
end
