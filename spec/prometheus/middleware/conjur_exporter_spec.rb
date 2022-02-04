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
  end
end