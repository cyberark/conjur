# frozen_string_literal: true

require 'delegate'
require 'openssl'

module Authentication
  module AuthnK8s
    # A secure socket wraps an existing TCP socket and establishes a secure
    # TLS context with it.
    #
    # :reek:TooManyInstanceVariables
    class SecureTcpSocket < SimpleDelegator
      def self.default_cert_store
        OpenSSL::X509::Store.new.tap(&:set_default_paths)
      end

      def initialize(
        socket:,

        # Optional keyword arguments to configure the TLS behavior
        hostname: nil,
        headers: nil,
        cert_store: SecureTcpSocket.default_cert_store,
        verify_mode: OpenSSL::SSL::VERIFY_PEER
      )
        @socket = socket

        @hostname = hostname
        @headers = headers
        @cert_store = cert_store
        @verify_mode = verify_mode

        super(secure_socket)
      end

      protected

      def secure_socket
        # Wrap the provided TCP socket with an SSLSocket
        OpenSSL::SSL::SSLSocket.new(@socket, openssl_context).tap do |socket|
          # support SNI, see https://www.cloudflare.com/en-gb/learning/ssl/what-is-sni/
          # don't set SNI hostname for IP address per RFC 6066, section 3.
          socket.hostname = @hostname unless ip_address?

          # Establish secure connection
          socket.connect
          socket.post_connection_check(@hostname)
        end
      end

      def ip_address?
        @hostname.match?(Resolv::IPv4::Regex) ||
          @hostname.match?(Resolv::IPv6::Regex)
      end

      def openssl_context
        OpenSSL::SSL::SSLContext.new.tap do |ctx|
          # Set the certificate store
          ctx.cert_store = @cert_store

          # Verify the TLS peer by default unless a verify mode is specified
          ctx.verify_mode = @verify_mode

          # Avoid openssl warning on hostname verification for IP address
          ctx.verify_hostname = false if ip_address?
        end
      end
    end
  end
end
