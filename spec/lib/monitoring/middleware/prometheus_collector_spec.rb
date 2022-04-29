require 'spec_helper'
require 'monitoring/middleware/prometheus_collector'
require 'monitoring/prometheus'
require 'monitoring/metrics'
Dir.glob(Rails.root + 'lib/monitoring/metrics/api_*.rb', &method(:require))


describe Monitoring::Middleware::PrometheusCollector do

  # Clear out any existing subscribers and reset the data store
  before do
    pubsub.unsubscribe('conjur.request_exception')
    pubsub.unsubscribe('conjur.request')
    Monitoring::Prometheus.setup(registry: Prometheus::Client::Registry.new, metrics: metrics)
  end

  let(:metrics) { [
    Monitoring::Metrics::ApiRequestCounter.new,
    Monitoring::Metrics::ApiRequestHistogram.new,
    Monitoring::Metrics::ApiExceptionCounter.new
  ] }

  let(:registry) { Monitoring::Prometheus.registry }

  let(:request_counter_metric) { registry.get(:conjur_http_server_requests_total) }

  let(:request_duration_metric) { registry.get(:conjur_http_server_request_duration_seconds) }

  let(:env) { Rack::MockRequest.env_for }

  let(:app) do
    app = ->(env) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }
  end

  let(:pubsub) { Monitoring::PubSub.instance }

  let(:options) { { pubsub: pubsub } }

  subject { described_class.new(app, **options) }

  it 'returns the app response' do
    env['PATH_INFO'] = "/foo"
    status, _headers, _response = subject.call(env)

    expect(status).to eql(200)
    expect(_response.first).to eql('OK')
  end

  it 'traces request information' do
    expect(Benchmark).to receive(:realtime).and_yield.and_return(0.2)

    env['PATH_INFO'] = "/foo"
    status, _headers, _response = subject.call(env)

    labels = { operation: 'unknown', code: '200' }
    expect(request_counter_metric.get(labels: labels)).to eql(1.0)

    labels = { operation: 'unknown' }
    expect(request_duration_metric.get(labels: labels)).to include("0.1" => 0, "0.25" => 1)
  end

  it 'stores a known operation ID in the metrics store' do
    expect(Benchmark).to receive(:realtime).and_yield.and_return(0.2)

    env['PATH_INFO'] = "/whoami"
    status, _headers, _response = subject.call(env)

    labels = { operation: 'whoAmI', code: '200' }
    expect(request_counter_metric.get(labels: labels)).to eql(1.0)

    labels = { operation: 'whoAmI' }
    expect(request_duration_metric.get(labels: labels)).to include("0.1" => 0, "0.25" => 1)
  end

  context 'when the app raises an exception' do

    let(:dummy_error) { RuntimeError.new('Dummy error from tests') }

    let(:request_exception_metric) { registry.get(:conjur_http_server_request_exceptions_total) }

    let(:app) do
      app = ->(env) { 
        raise dummy_error if env['PATH_INFO'] == '/broken'
        [200, { 'Content-Type' => 'text/html' }, ['OK']] 
      }
    end
  
    subject { described_class.new(app, **options) }

    before do
      subject.call(env)
    end

    it 'traces exceptions' do
      env['PATH_INFO'] = '/broken'
      expect { subject.call(env) }.to raise_error(RuntimeError)

      labels = {
        operation: 'unknown',
        exception: 'RuntimeError',
        message: 'Dummy error from tests'
      }

      expect(request_exception_metric.get(labels: labels)).to eql(1.0)
    end
  end
end
