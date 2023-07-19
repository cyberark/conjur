require 'spec_helper'
require 'monitoring/middleware/prometheus_exporter'

describe Monitoring::Middleware::PrometheusExporter do

  # Reset the data store
  before do
    Monitoring::Prometheus.setup(registry: Prometheus::Client::Registry.new)
  end
  
  let(:registry) do
    Monitoring::Prometheus.registry
  end

  let(:path) { '/metrics' }

  let(:options) { { registry: registry, path: path} }

  let(:env) { Rack::MockRequest.env_for }

  let(:app) do
    app = ->(env) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }
  end

  subject { described_class.new(app, **options) }

  context 'when requesting app endpoints' do
    it 'returns the app response' do
      env['PATH_INFO'] = "/foo"
      status, _headers, _response = subject.call(env)

      expect(status).to eql(200)
      expect(_response.first).to eql('OK')
    end
  end

  context 'when requesting /metrics' do
    text = Prometheus::Client::Formats::Text

    shared_examples 'ok' do |headers, fmt|
      it "responds with 200 OK and Content-Type #{fmt::CONTENT_TYPE}" do
        registry.counter(:foo, docstring: 'foo counter').increment(by: 9)
        
        env['PATH_INFO'] = path
        env['HTTP_ACCEPT'] = headers.values[0] if headers.values[0]

        status, _headers, _response = subject.call(env)

        expect(status).to eql(200)
        expect(_headers['Content-Type']).to eql(fmt::CONTENT_TYPE)
        expect(_response.first).to eql(fmt.marshal(registry))

      end
    end

    shared_examples 'not acceptable' do |headers|
      it 'responds with 406 Not Acceptable' do
        message = 'Supported media types: text/plain'

        env['PATH_INFO'] = path
        env['HTTP_ACCEPT'] = headers.values[0] if headers.values[0]

        status, _headers, _response = subject.call(env)

        expect(status).to eql(406)
        expect(_headers['Content-Type']).to eql('text/plain')
        expect(_response.first).to eql(message)
      end
    end

    context 'when client does not send a Accept header' do
      include_examples 'ok', {}, text
    end

    context 'when client accepts any media type' do
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
  end
end
