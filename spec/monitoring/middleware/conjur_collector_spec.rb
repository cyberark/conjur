require 'spec_helper'
require 'rack/test'
require 'prometheus/client/formats/text'
require ::File.expand_path('../../../../lib/monitoring/middleware/conjur_collector.rb', __FILE__)
require ::File.expand_path('../../../../lib/monitoring/metrics.rb', __FILE__)

describe Prometheus::Middleware::ConjurCollector do
  include Rack::Test::Methods

  # Reset the data store
  before do
    Monitoring::Metrics.setup(registry: Prometheus::Client::Registry.new)
  end

  let(:registry) do
    Monitoring::Metrics.registry
  end

  let(:original_app) do
    ->(_) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }
  end

  let!(:app) do
    described_class.new(original_app)
  end

  let(:dummy_error) { RuntimeError.new("Dummy error from tests") }

  it 'returns the app response' do
    get '/foo'

    expect(last_response).to be_ok
    expect(last_response.body).to eql('OK')
  end

  it 'handles errors in the registry gracefully' do
    counter = registry.get(:conjur_http_server_requests_total)
    expect(counter).to receive(:increment).and_raise(dummy_error)

    get '/foo'

    expect(last_response).to be_ok
  end

  it 'traces request information' do
    expect(Benchmark).to receive(:realtime).and_yield.and_return(0.2)

    get '/foo'

    metric = :conjur_http_server_requests_total
    labels = { method: 'GET', path: '/foo', code: '200' }
    expect(registry.get(metric).get(labels: labels)).to eql(1.0)

    metric = :conjur_http_server_request_duration_seconds
    labels = { method: 'GET', path: '/foo' }
    expect(registry.get(metric).get(labels: labels)).to include("0.1" => 0, "0.25" => 1)
  end

  it 'includes SCRIPT_NAME in the path if provided' do
    metric = :conjur_http_server_requests_total

    get '/foo'

    expect(registry.get(metric).values.keys.last[:path]).to eql("/foo")

    env('SCRIPT_NAME', '/engine')
    get '/foo'
    env('SCRIPT_NAME', nil)
    expect(registry.get(metric).values.keys.last[:path]).to eql("/engine/foo")
  end

  it 'normalizes paths containing numeric IDs by default' do
    expect(Benchmark).to receive(:realtime).and_yield.and_return(0.3)

    get '/foo/42/bars'

    metric = :conjur_http_server_requests_total
    labels = { method: 'GET', path: '/foo/:id/bars', code: '200' }
    expect(registry.get(metric).get(labels: labels)).to eql(1.0)

    metric = :conjur_http_server_request_duration_seconds
    labels = { method: 'GET', path: '/foo/:id/bars' }
    expect(registry.get(metric).get(labels: labels)).to include("0.1" => 0, "0.5" => 1)
  end

  it 'normalizes paths containing UUIDs by default' do
    expect(Benchmark).to receive(:realtime).and_yield.and_return(0.3)

    get '/foo/5180349d-a491-4d73-af30-4194a46bdff3/bars'

    metric = :conjur_http_server_requests_total
    labels = { method: 'GET', path: '/foo/:uuid/bars', code: '200' }
    expect(registry.get(metric).get(labels: labels)).to eql(1.0)

    metric = :conjur_http_server_request_duration_seconds
    labels = { method: 'GET', path: '/foo/:uuid/bars' }
    expect(registry.get(metric).get(labels: labels)).to include("0.1" => 0, "0.5" => 1)
  end

  it 'handles consecutive path segments containing IDs' do
    expect(Benchmark).to receive(:realtime).and_yield.and_return(0.3)

    get '/foo/42/24'

    metric = :conjur_http_server_requests_total
    labels = { method: 'GET', path: '/foo/:id/:id', code: '200' }
    expect(registry.get(metric).get(labels: labels)).to eql(1.0)

    metric = :conjur_http_server_request_duration_seconds
    labels = { method: 'GET', path: '/foo/:id/:id' }
    expect(registry.get(metric).get(labels: labels)).to include("0.1" => 0, "0.5" => 1)
  end

  it 'handles consecutive path segments containing UUIDs' do
    expect(Benchmark).to receive(:realtime).and_yield.and_return(0.3)

    get '/foo/5180349d-a491-4d73-af30-4194a46bdff3/5180349d-a491-4d73-af30-4194a46bdff2'

    metric = :conjur_http_server_requests_total
    labels = { method: 'GET', path: '/foo/:uuid/:uuid', code: '200' }
    expect(registry.get(metric).get(labels: labels)).to eql(1.0)

    metric = :conjur_http_server_request_duration_seconds
    labels = { method: 'GET', path: '/foo/:uuid/:uuid' }
    expect(registry.get(metric).get(labels: labels)).to include("0.1" => 0, "0.5" => 1)
  end

  context 'when the app raises an exception' do
    let(:original_app) do
      lambda do |env|
        raise dummy_error if env['PATH_INFO'] == '/broken'

        [200, { 'Content-Type' => 'text/html' }, ['OK']]
      end
    end

    before do
      get '/foo'
    end

    it 'traces exceptions' do
      expect { get '/broken' }.to raise_error(RuntimeError)

      metric = :conjur_http_server_exceptions_total
      labels = { exception: 'RuntimeError' }

      expect(registry.get(metric).get(labels: labels)).to eql(1.0)
    end
  end

  context 'when provided a custom metrics_prefix' do
    before do
      Monitoring::Metrics.setup(metrics_prefix: 'lolrus')
    end

    it 'provides alternate metric names' do
      expect(
        registry.get(:lolrus_requests_total)
      ).to be_a(Prometheus::Client::Counter)
      expect(
        registry.get(:lolrus_request_duration_seconds)
      ).to be_a(Prometheus::Client::Histogram)
      expect(
        registry.get(:lolrus_exceptions_total)
      ).to be_a(Prometheus::Client::Counter)
    end

    it "doesn't register the default metrics" do
      expect(registry.get(:conjur_http_server_requests_total)).to be(nil)
      expect(registry.get(:conjur_http_server_request_duration_seconds)).to be(nil)
      expect(registry.get(:conjur_http_server_exceptions_total)).to be(nil)
    end
  end
end
