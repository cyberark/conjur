require 'spec_helper'
require 'rack/test'
require 'monitoring/middleware/conjur_collector'
require 'monitoring/middleware/prometheus_exporter'
require 'monitoring/prometheus'

describe Monitoring::Middleware::ConjurCollector do
  include Rack::Test::Methods

  before do
    Monitoring::Prometheus.setup(registry: Prometheus::Client::Registry.new)
  end

  let(:registry) do
    Monitoring::Prometheus.registry
  end

  let(:collector_options) {{ registry: registry, pubsub: Monitoring::PubSub }}
  let(:exporter_options) {{ registry: registry, path: '/metrics' }}

  let(:app) do
    app = ->(_) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }

    # Wrap the mock app with the Collector and Exporter middleware
    app_with_collector = described_class.new(app, **collector_options)
    Monitoring::Middleware::PrometheusExporter.new(app_with_collector, **exporter_options)
  end

  it 'returns the app response' do
    get '/foo'
    expect(last_response).to be_ok
    expect(last_response.body).to eql('OK')
  end

  it 'metrics from traced requests update the global registry' do
    get '/foo'

    metric = :collector_test_metric
    labels = { path: '/foo', code: 200 }
    expect(registry.get(metric).get(labels: labels)).to eql(1.0)
  end

  it 'metrics updated through the collector are exposed by the exporter' do
    text = Prometheus::Client::Formats::Text

    get '/foo'
    get '/metrics'

    expect(last_response.status).to eql(200)
    expect(last_response.body).to eql(text.marshal(registry))
  end
end
