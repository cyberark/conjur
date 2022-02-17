# frozen_string_literal: true

require 'spec_helper'

class TestServer
  attr_reader(:handshake)
  attr_reader(:ca)
  attr_reader(:message)

  def initialize(port)
    @port = port
    @server = TCPServer.open("127.0.0.1", port)
  end

  def add_old_ssl(host)
    build_ca
    @server = OpenSSL::SSL::SSLServer.new(@server, build_ssl_context(:SSLv23, build_cert(host)))
  end

  def add_tls_without_sni(host)
    build_ca
    @server = OpenSSL::SSL::SSLServer.new(@server, build_ssl_context(:TLSv1, build_cert(host)))
  end

  def add_tls_with_sni
    build_ca
    testing_com_cert = build_cert("testing.com")
    another_site_com_cert = build_cert("another-site.com")
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.servername_cb = proc { |ssl_socket, hostname|
      new_context = OpenSSL::SSL::SSLContext.new
      new_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      new_context.ssl_version = :TLSv1
      new_context.key = OpenSSL::PKey::RSA.new(@ca.key)

      case hostname
      when "testing.com"
        new_context.cert = OpenSSL::X509::Certificate.new(testing_com_cert)
      else
        new_context.cert = OpenSSL::X509::Certificate.new(another_site_com_cert)
      end

      new_context
    }
    @server = OpenSSL::SSL::SSLServer.new(@server, ssl_context)
  end

  def add_websocket
    @handshake = WebSocket::Handshake::Server.new(host: "127.0.0.1", port: @port)
  end

  def add_bad_websocket
    @handshake = WebSocket::Handshake::Server.new(host: "127.0.0.1", port: @port)
    @bad_handshake = true
  end

  def run
    @thread = Thread.new do
      client = @server.accept
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
  end

  def close
    @thread.kill if @thread
    @server.close
  end

  private

  def build_cert(common_name)
    @ca.signed_cert(
      Util::OpenSsl::X509::SmartCsr.new(
        Util::OpenSsl::X509::QuickCsr.new(common_name: common_name, rsa_key: @ca.key).request
      )
    )
  end

  def build_ca
    @ca ||= Util::OpenSsl::CA.from_subject("/CN=testing.com/OU=Conjur Kubernetes CA/O=user")
  end

  def build_ssl_context(ssl_version, cert)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    ssl_context.ssl_version = ssl_version
    ssl_context.key = OpenSSL::PKey::RSA.new(@ca.key)
    ssl_context.cert = OpenSSL::X509::Certificate.new(cert)
    ssl_context
  end
end

describe 'Authentication::AuthnK8s::WebSocketClient' do
  context 'no server running' do
    before(:example) do
    end

    after(:example) do
    end

    it 'fails to connect' do
      expect {
        Authentication::AuthnK8s::WebSocketClient.connect("https://127.0.0.1")
      }.to raise_error(Errno::ECONNREFUSED)
    end
  end

  context 'server running - no web socket' do
    before(:example) do
      @test_server = TestServer.new(80)
    end

    after(:example) do
      @test_server.close
      @test_server = nil
    end

    it 'fails to connect - no web socket server' do
      client = Authentication::AuthnK8s::WebSocketClient.connect("http://127.0.0.1")
      expect(client.open?).to be_falsey
    end
  end

  context 'server running - no security' do
    before(:example) do
      @test_server = TestServer.new(80)
    end

    after(:example) do
      @test_server.close
      @test_server = nil
    end

    it 'connects with no options' do
      @test_server.add_websocket
      @test_server.run
      client = Authentication::AuthnK8s::WebSocketClient.connect("ws://127.0.0.1")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'connects with options' do
      @test_server.add_websocket
      @test_server.run
      client = Authentication::AuthnK8s::WebSocketClient.connect("ws://127.0.0.1",
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                                                 hostname: "testing.com")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'does not connect with a bad handshake' do
      @test_server.add_bad_websocket
      @test_server.run
      client = Authentication::AuthnK8s::WebSocketClient.connect("ws://127.0.0.1")
      sleep(1)
      expect(client.open?).to be_falsey
      client.close
    end
  end

  context 'server running - with old security' do
    before(:example) do
      @test_server = TestServer.new(443)
      @test_server.add_old_ssl("127.0.0.1")
    end

    after(:example) do
      @test_server.close
      @test_server = nil
    end

    it 'does not connect with a bad handshake' do
      @test_server.add_bad_websocket
      @test_server.run
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_falsey
      client.close
    end

    it 'connects properly without options' do
      @test_server.add_websocket
      @test_server.run
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'connects properly with options' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :SSLv23,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER)
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'connects properly with hostname' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :SSLv23,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                                                 hostname: "127.0.0.1")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end
  end

  context 'server running - with tls security - no SNI' do
    before(:example) do
      @test_server = TestServer.new(443)
      @test_server.add_tls_without_sni("127.0.0.1")
    end

    after(:example) do
      @test_server.close
      @test_server = nil
    end

    it 'does not connect with a bad handshake' do
      @test_server.add_bad_websocket
      @test_server.run
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_falsey
      client.close
    end

    it 'connects properly without options' do
      @test_server.add_websocket
      @test_server.run
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'connects properly with options' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :TLSv1,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER)
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'connects properly with hostname' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :TLSv1,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                                                 hostname: "127.0.0.1")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'does not connect properly with bad hostname' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      expect { Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :TLSv1,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                                                 hostname: "bad.com")
      }.to raise_error(OpenSSL::SSL::SSLError, nil) {
        |error| expect(error.message).to eq("hostname \"bad.com\" does not match the server certificate")
      }
    end
  end

  context 'server running - with tls security - with SNI' do
    before(:example) do
      @test_server = TestServer.new(443)
      @test_server.add_tls_with_sni
    end

    after(:example) do
      @test_server.close
      @test_server = nil
    end

    it 'does not connect with a bad handshake' do
      @test_server.add_bad_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :TLSv1,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                                                 hostname: "testing.com")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_falsey
      client.close
    end

    it 'does not connect properly without options' do
      @test_server.add_websocket
      @test_server.run
      expect { Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1")
      }.to raise_error(OpenSSL::SSL::SSLError, nil) {
        |error| expect(error.message).to eq("SSL_connect returned=1 errno=0 state=SSLv2/v3 read server hello A: sslv3 alert handshake failure")
      }
    end

    it 'does not connect properly missing the hostname and no cert available for "127.0.0.1"' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      expect { client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                          ssl_version: :TLSv1,
                                                                          cert_store: cert_store,
                                                                          verify_mode: OpenSSL::SSL::VERIFY_PEER)
      }.to raise_error(OpenSSL::SSL::SSLError, nil) {
        |error| expect(error.message).to eq("hostname \"127.0.0.1\" does not match the server certificate")
      }
    end

    it 'connects properly with hostname' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :TLSv1,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                                                 hostname: "testing.com")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'connects properly with a different hostname' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :TLSv1,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                                                 hostname: "another-site.com")
      sleep(1)
      expect(@test_server.handshake).to be_truthy
      expect(@test_server.handshake.valid?).to be_truthy
      expect(@test_server.handshake.finished?).to be_truthy
      expect(client.open?).to be_truthy
      client.close
    end

    it 'does not connect properly with bad hostname' do
      @test_server.add_websocket
      @test_server.run
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert(@test_server.ca.cert)
      expect { Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1",
                                                                 ssl_version: :TLSv1,
                                                                 cert_store: cert_store,
                                                                 verify_mode: OpenSSL::SSL::VERIFY_PEER,
                                                                 hostname: "bad.com")
      }.to raise_error(OpenSSL::SSL::SSLError, nil) {
        |error| expect(error.message).to eq("hostname \"bad.com\" does not match the server certificate")
      }
    end
  end
end