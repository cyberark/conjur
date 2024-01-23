# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Util::NetworkTransporter) do
  let(:http_client) do
    class_double(Net::HTTP).tap do |double|
      allow(double).to receive(:new).with(hostname.gsub(%r{^https?://}, ''), port).and_return(http)
    end
  end
  let(:http) do
    instance_double(Net::HTTP).tap do |double|
      allow(double).to receive(:use_ssl=).with(true)
      allow(double).to receive(:verify_mode=).with(1)
      allow(double).to receive(:cert_store=).with(an_instance_of(OpenSSL::X509::Store))
      allow(double).to receive(:start).and_yield(http_transport)
    end
  end
  let(:http_transport) do
    instance_double(Net::HTTP).tap do |double|
      allow(double).to receive(:get).with(path).and_return(response)
    end
  end
  let(:response) do
    instance_double(Net::HTTPResponse).tap do |double|
      allow(double).to receive(:code).and_return(response_code)
      allow(double).to receive(:body).and_return(response_message)
      allow(double).to receive(:uri).and_return(error_uri)
    end
  end
  let(:error_uri) { nil }
  let(:response_code) { '200' }
  let(:transport) { described_class.new(hostname: hostname, http: http_client) }

  describe('.get') do
    let(:path) { '/.well-known/openid-configuration' }
    let(:response_message) { '{"foo": "bar", "baz": 2}' }
    context 'when the connection is https' do
      let(:hostname) { 'https://accounts.google.com' }
      let(:port) { 443 }
      context 'when the tls connection uses a public certificate' do
        context 'when the response is a valid success code' do
          context 'when the response is valid JSON' do
            %w[200 201].each do |code|
              let(:response_code) { code }
              it 'correctly parses the response' do
                response = transport.get(path)
                expect(response.success?).to be(true)

                result = response.result
                expect(result.class).to eq(Hash)
                expect(result['foo']).to eq('bar')
                expect(result['baz']).to eq(2)
              end
            end
          end
          [nil, '', '{'].each do |response_body|
            context "when the response is invalid JSON: '#{response_body}'" do
              let(:response_message) { response_body }
              it 'is unsuccessful' do
                response = transport.get(path)

                expect(response.success?).to be(false)
                expect(response.message).to eq("Invalid JSON: unexpected token at '#{response_body}'")
                expect(response.exception.class).to eq(JSON::ParserError)
                expect(response.status).to eq(:bad_request)
              end
            end
          end
        end
        %w[301 400 404 403].each do |code|
          context "when the response is an invalid response '#{code}'" do
            let(:response_message) { nil }
            let(:error_uri) {'https://accounts.google.com/.well-known/openid-configuration'}
            let(:response_code) { code }
            it 'returns an expected error' do
              result = transport.get(path)

              expect(result.success?).to be(false)
              expect(result.message).to eq("Error Response Code: '#{code}' from 'https://accounts.google.com/.well-known/openid-configuration'")
            end
          end
        end
      end
      context 'when the certificate is self-signed' do
        let(:certificate) do
          Util::OpenSsl::X509::Certificate.from_subject(
            subject: 'CN=Test CA'
          )
        end
        it 'correctly parses the response' do
          # Spy to ensure expected certificate is used
          certificate_utilities = double(Conjur::CertUtils)
          expect(certificate_utilities).to receive(:add_chained_cert).with(
            an_instance_of(OpenSSL::X509::Store),
            certificate.to_s
          )
          transport = described_class.new(hostname: hostname, ca_certificate: certificate.to_s, http: http_client, certificate_utilities: certificate_utilities)
          response = transport.get(path)
          expect(response.success?).to be(true)

          result = response.result
          expect(result.class).to eq(Hash)
          expect(result['foo']).to eq('bar')
          expect(result['baz']).to eq(2)
        end
      end
    end
    context 'when connection does not use TLS' do
      let(:http) do
        instance_double(Net::HTTP).tap do |double|
          allow(double).to receive(:start).and_yield(http_transport)
        end
      end
      let(:hostname) { 'http://accounts.google.com' }
      let(:port) { 80 }
      it 'is successful' do
        response = transport.get(path)
        expect(response.success?).to be(true)

        result = response.result
        expect(result.class).to eq(Hash)
        expect(result['foo']).to eq('bar')
        expect(result['baz']).to eq(2)
      end
    end
  end
  describe('.post') do
    let(:http_transport) do
      instance_double(Net::HTTP).tap do |double|
        allow(double).to receive(:request).with(post).and_return(response)
      end
    end
    let(:post_class) do
      class_double(Net::HTTP::Post).tap do |double|
        allow(double).to receive(:new).with(path).and_return(post)
      end
    end
    let(:post) { instance_double(Net::HTTP::Post) }
    let(:transport) { described_class.new(hostname: 'https://accounts.google.com/o/oauth2/v2/auth', http: http_client, http_post: post_class) }
    let(:hostname) { 'accounts.google.com' }
    let(:path) { '/o/oauth2/v2/auth' }
    let(:port) { 443 }
    let(:response_message) { '{"foo": "bar", "baz": 2}' }

    let(:request) do
      request = Net::HTTP::Post.new(URI(path).path)
      request.body = ''
    end
    it 'correctly configures and executes the request' do
      # Spy to ensure post receives expected configuration
      expect(post).to receive(:body=).with('')

      response = transport.post(path: 'https://accounts.google.com/o/oauth2/v2/auth')
      expect(response.success?).to be(true)

      result = response.result
      expect(result.class).to eq(Hash)
      expect(result['foo']).to eq('bar')
      expect(result['baz']).to eq(2)
    end

    context 'with headers' do
      it 'adds the provided headers' do
        headers = {
          'Authorization' => 'Basic abc123',
          'Transfer-Encoding' => 'gzip'
        }

        # Spies
        expect(post).to receive(:body=).with('')
        headers.each do |key, value|
          expect(post).to receive(:[]=).with(key, value)
        end

        response = transport.post(
          path: 'https://accounts.google.com/o/oauth2/v2/auth',
          headers: headers
        )
        expect(response.success?).to be(true)
      end
    end
    context 'with a body' do
      it 'adds the provided body' do
        # Spies
        expect(post).to receive(:body=).with('foo=bar&baz=bing')

        response = transport.post(
          path: 'https://accounts.google.com/o/oauth2/v2/auth',
          body: 'foo=bar&baz=bing'
        )
        expect(response.success?).to be(true)
      end
    end
    context 'with basic auth' do
      it 'adds the provided basic auth values' do
        # Spies
        expect(post).to receive(:body=).with('')
        expect(post).to receive(:basic_auth).with('username', 'password')

        response = transport.post(
          path: 'https://accounts.google.com/o/oauth2/v2/auth',
          basic_auth: %w[username password]
        )
        expect(response.success?).to be(true)
      end
    end
  end
end
