require 'socket'
require 'openssl'
require 'websocket'

require "domain/util/open_ssl/ca"
require "domain/util/open_ssl/x509/quick_csr"
require "domain/util/open_ssl/x509/smart_csr"

class WebSocketTestServer
    attr_reader(:handshake)
    attr_reader(:ca)
    attr_reader(:port)
    attr_reader(:message)
    attr_accessor(:should_log)

    def initialize(port = 0)
      @should_log = false
      @port = port
      @server = TCPServer.open("0.0.0.0", @port)
  
      if @port == 0
        @port = @server.addr[1]
      end

      @server
    end

    def add_tls_without_sni(host)
      build_ca
      @server = OpenSSL::SSL::SSLServer.new(@server, build_ssl_context(:TLSv1_2_server, build_cert(host)))
    end

    def add_tls_with_sni
      build_ca
      default_site_com_cert = build_cert("default.com")
      testing_com_cert = build_cert("testing.com")

      ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1_2_server)
  
      # default context when there is no SNI (for example connection via IP or no servername is sent)
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      ssl_context.key = OpenSSL::PKey::RSA.new(@ca.key)
      ssl_context.cert = OpenSSL::X509::Certificate.new(default_site_com_cert)
  
      # create context depending on SNI
      ssl_context.servername_cb = proc { |ssl_socket, hostname|
        new_context = OpenSSL::SSL::SSLContext.new(:TLSv1_2_server)

        new_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
        new_context.key = OpenSSL::PKey::RSA.new(@ca.key)
        case hostname
        when "testing.com"
          new_context.cert = OpenSSL::X509::Certificate.new(testing_com_cert)
        else
          new_context.cert = OpenSSL::X509::Certificate.new(default_site_com_cert)
        end
  
        new_context
      }
      @server = OpenSSL::SSL::SSLServer.new(@server, ssl_context)
    end

    def add_websocket
      @handshake = WebSocket::Handshake::Server.new(host: "localhost", port: @port)
    end

    def good_handshake?
      @handshake && @handshake.finished? && @handshake.valid?
    end

    def add_bad_websocket
      @handshake = WebSocket::Handshake::Server.new(host: "localhost", port: @port)
      @bad_handshake = true
    end

    def run
      return if @thread
      log "test server: running server at #{@port}"

      @thread = Thread.new do
        log "test server: waiting for connection"
        begin
            client = @server.accept
        rescue => e 
          log "test server: failed to accept connection", e
            @thread.kill
        end

        log "test server: accepted connection"
        string = ""
        while part = client.gets
          string = string + part
          break if string =~ /Sec-WebSocket-Key/
        end
        if @handshake
          @handshake << string + "\r\n"
          if @bad_handshake
            client.puts("bad handshake")
          else
            client.puts(@handshake.to_s)
          end
        end
      end
      @thread.abort_on_exception = true
    end

    def close
      @thread.kill if @thread
      @server.close
    end

    private

    def log(*args, &block)
      return unless @should_log

      puts(*args, &block)
    end

    def build_cert(common_name)
      @ca.signed_cert(
        Util::OpenSsl::X509::SmartCsr.new(
          Util::OpenSsl::X509::QuickCsr.new(common_name: common_name, rsa_key: @ca.key).request
        ),
        subject_altnames: ["DNS:#{common_name}", "IP:127.0.0.1"] # because verification is either CN or SAN, not both :()
      )
    end
  
    def build_ca
      @ca ||= Util::OpenSsl::CA.from_subject("/CN=ca-testing.com/OU=Conjur Kubernetes CA/O=user")
    end

    def build_ssl_context(ssl_version, cert)
      ssl_context = OpenSSL::SSL::SSLContext.new()
      ssl_context.ssl_version = ssl_version if ssl_version
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      ssl_context.key = OpenSSL::PKey::RSA.new(@ca.key)
      ssl_context.cert = OpenSSL::X509::Certificate.new(cert)
      ssl_context
    end
end
