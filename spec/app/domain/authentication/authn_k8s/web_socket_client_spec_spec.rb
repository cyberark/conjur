# frozen_string_literal: true

# Run this file by calling:
# bundle exec rspec spec/app/domain/authentication/authn_k8s/web_socket_client_spec_spec.rb --format documentation

require 'openssl'

require 'domain/authentication/authn_k8s/web_socket_client'

require_relative './web_socket_test_server.rb'
require_relative '../../../../../config/initializers/openssl.rb'

describe 'Authentication::AuthnK8s::WebSocketClient' do
  context 'server not running' do
    it 'fails to connect' do
      expect {
        @client = Authentication::AuthnK8s::WebSocketClient.connect("https://127.0.0.1:91239") # Strange issue where if "localhost" is used the error becomes EADDRNOTAVAIL
      }.to raise_error(Errno::ECONNREFUSED)
    end
  end
end

describe 'Authentication::AuthnK8s::WebSocketClient' do
  context 'server running' do  
    context 'without TLS' do
      before(:example) do
        @test_server = WebSocketTestServer.new
        @client = nil
      end
  
      after(:example) do
        @test_server.close
        @client && @client.close
        @test_server = nil
        @client = nil
      end
  
      it 'has good handshake with no options' do
        @test_server.add_websocket
        @test_server.run
        @client  = Authentication::AuthnK8s::WebSocketClient.connect("ws://localhost:#{@test_server.port}")
        sleep(1)
        expect(@test_server.good_handshake?).to be_truthy
        expect(@client.open?).to be_truthy
      end
  
      it 'has good handshake with options' do
        @test_server.add_websocket
        @test_server.run
        @client = Authentication::AuthnK8s::WebSocketClient.connect("ws://localhost:#{@test_server.port}",
                                                                   cert_store: OpenSSL::X509::Store.new)
        sleep(1)
        expect(@test_server.good_handshake?).to be_truthy
        expect(@client.open?).to be_truthy
      end
  
      it 'is not open for communication without a good handshake' do
        @test_server.add_bad_websocket
        @test_server.run
        @client = Authentication::AuthnK8s::WebSocketClient.connect("ws://localhost:#{@test_server.port}")
        sleep(1)
        expect(@client.open?).to be_falsey
      end
    end

    context 'with TLS and no SNI' do
      before(:example) do
        @test_server = WebSocketTestServer.new
        @test_server.add_tls_without_sni("good.com")
        @client = nil
      end

      after(:example) do
        @client.close if @client
        @test_server.close
        @test_server = nil
        @client = nil
      end

      it 'fails cert verification without options' do
        @test_server.add_websocket
        @test_server.run
        expect { 
          @client = Authentication::AuthnK8s::WebSocketClient.connect("wss://localhost:#{@test_server.port}")
        }.to raise_error(OpenSSL::SSL::SSLError, nil) {  |error|
           expect(error.message).to eq("SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate)") 
        }
      end
  
      it 'passes all TLS verifications with good options' do
        @test_server.add_websocket
        @test_server.run
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert(@test_server.ca.cert)
        @client = Authentication::AuthnK8s::WebSocketClient.connect("wss://localhost:#{@test_server.port}",
                                                                   cert_store: cert_store,
                                                                   hostname: "good.com")
        sleep(1)
        expect(@test_server.good_handshake?).to be_truthy
        expect(@client.open?).to be_truthy
      end

      it 'fails hostname verification with bad hostname' do
        @test_server.add_websocket
        @test_server.run
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert(@test_server.ca.cert)

        expect { @client = Authentication::AuthnK8s::WebSocketClient.connect("wss://localhost:#{@test_server.port}",
                                                                   cert_store: cert_store)
        }.to raise_error(OpenSSL::SSL::SSLError, nil) {
          |error| expect(error.message).to eq("hostname \"localhost\" does not match the server certificate")
        }
      end

      it 'fails hostname verification for bad ip' do
        @test_server.add_websocket
        @test_server.run
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert(@test_server.ca.cert)
        expect { Authentication::AuthnK8s::WebSocketClient.connect("wss://0.0.0.0:#{@test_server.port}",
                                                                   cert_store: cert_store)
        }.to raise_error(OpenSSL::SSL::SSLError, nil) {
          |error| expect(error.message).to eq("hostname \"0.0.0.0\" does not match the server certificate")
        }
      end

      it 'passes hostname verification for good ip' do
        @test_server.add_websocket
        @test_server.run
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert(@test_server.ca.cert)
        @client = Authentication::AuthnK8s::WebSocketClient.connect("wss://127.0.0.1:#{@test_server.port}",
          cert_store: cert_store)
        sleep(1)
        expect(@test_server.good_handshake?).to be_truthy
        expect(@client.open?).to be_truthy
      end
    end

    context 'with TLS and SNI' do
      before(:example) do
        @test_server = WebSocketTestServer.new
        @test_server.add_tls_with_sni
      end

      after(:example) do
        @test_server.close
        @test_server = nil
      end

      it 'fails cert verification without options' do
        @test_server.add_websocket
        @test_server.run
        expect { 
          @client = Authentication::AuthnK8s::WebSocketClient.connect("wss://localhost:#{@test_server.port}")
        }.to raise_error(OpenSSL::SSL::SSLError, nil) {  |error|
           expect(error.message).to eq("SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate)") 
        }
      end

      it 'passes all TLS verifications with options for default SNI cert with good hostname' do
        @test_server.add_websocket
        @test_server.run
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert(@test_server.ca.cert)
        @client = Authentication::AuthnK8s::WebSocketClient.connect("wss://localhost:#{@test_server.port}",
                                                                   cert_store: cert_store,
                                                                   hostname: "default.com")
        sleep(1)
        expect(@test_server.good_handshake?).to be_truthy
        expect(@client.open?).to be_truthy
      end

      it 'fails hostname verification with options for default SNI cert with bad hostname' do
        @test_server.add_websocket
        @test_server.run
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert(@test_server.ca.cert)
        expect { @client = Authentication::AuthnK8s::WebSocketClient.connect("wss://localhost:#{@test_server.port}",
                                                                            cert_store: cert_store)
        }.to raise_error(OpenSSL::SSL::SSLError, nil) {
          |error| expect(error.message).to eq("hostname \"localhost\" does not match the server certificate")
        }
      end

      it 'passes all TLS verifications with options for non-default SNI cert' do
        @test_server.add_websocket
        @test_server.run
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert(@test_server.ca.cert)
        @client = Authentication::AuthnK8s::WebSocketClient.connect("wss://localhost:#{@test_server.port}",
                                                                   cert_store: cert_store,
                                                                   hostname: "testing.com")
        sleep(1)
        expect(@test_server.good_handshake?).to be_truthy
        expect(@client.open?).to be_truthy
      end
    end
  end

end
