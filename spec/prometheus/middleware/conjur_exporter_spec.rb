# encoding: UTF-8
require 'rack/test'
require ::File.expand_path('../../../../lib/prometheus/conjur_exporter.rb', __FILE__)

describe Prometheus::Middleware::ConjurExporter do
  include Rack::Test::Methods

  let(:options) { { registry: registry } }
  let(:registry) do
    Prometheus::Client::Registry.new
  end

  let(:app) do
    app = ->(_) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }
    described_class.new(app, **options)
  end

  context 'when requesting app endpoints' do
    it 'returns the app response' do
      get '/foo'

      expect(last_response).to be_ok
      expect(last_response.body).to eql('OK')
    end
  end

  context 'when requesting /metrics' do
    text = Prometheus::Client::Formats::Text

    shared_examples 'ok' do |headers, fmt|
      it "responds with 200 OK and Content-Type #{fmt::CONTENT_TYPE}" do
        registry.counter(:foo, docstring: 'foo counter').increment(by: 9)

        get '/metrics', nil, headers

        expect(last_response.status).to eql(200)
        expect(last_response.header['Content-Type']).to eql(fmt::CONTENT_TYPE)
        expect(last_response.body).to eql(fmt.marshal(registry))
      end
    end

    shared_examples 'not acceptable' do |headers|
      it 'responds with 406 Not Acceptable' do
        message = 'Supported media types: text/plain'

        get '/metrics', nil, headers

        expect(last_response.status).to eql(406)
        expect(last_response.header['Content-Type']).to eql('text/plain')
        expect(last_response.body).to eql(message)
      end
    end


    context 'when client does not send a Accept header' do
      include_examples 'ok', {}, text
    end

    context 'when client accpets any media type' do
      include_examples 'ok', { 'HTTP_ACCEPT' => '*/*' }, text
    end

    context 'when client requests application/json' do
      include_examples 'not acceptable', 'HTTP_ACCEPT' => 'application/json'
    end

    context 'when client requests text/plain' do
      include_examples 'ok', { 'HTTP_ACCEPT' => 'text/plain' }, text
    end

    context 'when client uses different white spaces in Accept header' do
      accept = 'text/plain;q=1.0  ; version=0.0.4'

      include_examples 'ok', { 'HTTP_ACCEPT' => accept }, text
    end

    context 'when client does not include quality attribute' do
      accept = 'application/json;q=0.5, text/plain'

      include_examples 'ok', { 'HTTP_ACCEPT' => accept }, text
    end

    context 'when client accepts some unknown formats' do
      accept = 'text/plain;q=0.3, proto/buf;q=0.7'

      include_examples 'ok', { 'HTTP_ACCEPT' => accept }, text
    end

    context 'when client accepts only unknown formats' do
      accept = 'fancy/woo;q=0.3, proto/buf;q=0.7'

      include_examples 'not acceptable', 'HTTP_ACCEPT' => accept
    end

    context 'when client accepts unknown formats and wildcard' do
      accept = 'fancy/woo;q=0.3, proto/buf;q=0.7, */*;q=0.1'

      include_examples 'ok', { 'HTTP_ACCEPT' => accept }, text
    end

    context 'when a port is specified' do
      let(:options) { { registry: registry, port: 9999 } }

      context 'when a request is on the specified port' do
        it 'responds with 200 OK' do
          registry.counter(:foo, docstring: 'foo counter').increment(by: 9)

          get 'http://example.org:9999/metrics', nil, {}

          expect(last_response.status).to eql(200)
          expect(last_response.header['Content-Type']).to eql(text::CONTENT_TYPE)
          expect(last_response.body).to eql(text.marshal(registry))
        end
      end

      context 'when a request is not on the specified port' do
        it 'returns the app response' do
          get 'http://example.org:8888/metrics', nil, {}

          expect(last_response).to be_ok
          expect(last_response.body).to eql('OK')
        end
      end
    end
  end
end