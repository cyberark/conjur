## This code is based on github.com/shokai/websocket-client-simple (MIT License)

require 'event_emitter'
require 'websocket'
require 'resolv'
require 'openssl'

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

      # connect provides options :hostname, :headers, :ssl_version, :cert_store, :verify_mode
      def connect(url, options = {})
        return if @socket

        @url = url
        uri = URI.parse(url)
        is_secure_connection = %w[https wss].include?(uri.scheme)
        @socket = TCPSocket.new(uri.host,
                                uri.port || (is_secure_connection ? 443 : 80))
        if is_secure_connection
          ctx = OpenSSL::SSL::SSLContext.new
          ssl_version = options[:ssl_version]
          ctx.ssl_version = ssl_version if ssl_version
          ctx.verify_mode = options[:verify_mode] || OpenSSL::SSL::VERIFY_PEER # use VERIFY_PEER for verification
          cert_store = options[:cert_store]

          unless cert_store
            cert_store = OpenSSL::X509::Store.new
            cert_store.set_default_paths
          end
          ctx.cert_store = cert_store

          use_sni = false
          ssl_host_address =  options[:hostname] || uri.host # use the param :hostname or default to the host of the url argument

          case uri.host
          when Resolv::IPv4::Regex, Resolv::IPv6::Regex
            # don't set SNI, as IP addresses in SNI is not valid
            # per RFC 6066, section 3.

            # Avoid openssl warning
            ctx.verify_hostname = false
          else
            use_sni = true
          end

          @socket = ::OpenSSL::SSL::SSLSocket.new(@socket, ctx)

          # support SNI, see https://www.cloudflare.com/en-gb/learning/ssl/what-is-sni/
          @socket.hostname = ssl_host_address if use_sni

          @socket.connect

          # mandatory hostname verification applicable to both hostnames and IP addresses
          @socket.post_connection_check(ssl_host_address)
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

                # completed handshake
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
          Rails.logger.error("Websocket failed to send: '#{data}'")
          Rails.logger.error("error: #{e}")
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
