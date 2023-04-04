# frozen_string_literal: true

require 'spec_helper'
require 'openssl'
require 'stringio'

require 'domain/authentication/authn_k8s/proxied_tcp_socket'

describe Authentication::AuthnK8s::ProxiedTcpSocket do
  describe '#new' do
    let(:proxy_uri) { URI.parse("http://proxy.local:8080") }
    let(:destination_host) { 'destination.example.com' }
    let(:destination_port) { 443 }
    let(:timeout) { 0.1 }

    let(:proxy_response) do
      "200 connection established\r\n\r\n"
    end

    let(:proxy_data) { StringIO.new }

    let(:tcp_socket_double) do
      instance_double(TCPSocket).tap do |tcp_socket_double|
        allow(tcp_socket_double).to receive(:write) do |value|
          proxy_data << value
        end

        allow(tcp_socket_double).to receive(:read).and_return(proxy_response)
      end
    end

    subject do
      described_class.new(
        proxy_uri: proxy_uri,
        destination_host: destination_host,
        destination_port: destination_port,
        timeout: timeout
      )
    end

    before do
      allow(TCPSocket).to receive(:new).and_return(tcp_socket_double)

      # IO#select requires an actual IO device, so we must mock the call and return
      # whether it is ready or not
      allow(IO).to receive(:select).and_return([[tcp_socket_double], nil, nil])
    end

    it "establishes a TCP connection through the configured proxy" do
      expect(TCPSocket).to receive(:new).with(
        proxy_uri.host,
        proxy_uri.port,
        connect_timeout: timeout
      )
      subject
    end

    it "sends the connect messages" do
      subject
      expect(proxy_data.string).to include(
        "CONNECT destination.example.com:443 HTTP/1.1\r\n" \
        "Host: destination.example.com\r\n\r\n"
      )
    end

    context "when the proxy connection fails" do
      let(:proxy_response) do
        "500 internal server error\r\n\r\n"
      end

      it "raises an exception" do
        expect { subject }.to raise_error(
          RuntimeError,
          "Proxy ('proxy.local:8080') returned an invalid response: " \
          "'500 internal server error'"
        )
      end
    end

    context "when proxy authorization is set" do
      let(:proxy_uri) { URI.parse("http://user:pass@proxy.local:8080") }

      it "include the proxy authorization header" do
        subject

        auth_value = Base64.strict_encode64(
          "#{proxy_uri.user}:#{proxy_uri.password}"
        )
        expect(proxy_data.string).to include(
          "Proxy-Authorization: Basic #{auth_value}"
        )
      end
    end

    context "when only proxy username is set" do
      let(:proxy_uri) { URI.parse("http://user@proxy.local:8080") }

      it "doesn't include the proxy authorization header" do
        subject

        expect(proxy_data.string).not_to include("Proxy-Authorization:")
      end
    end
  end
end