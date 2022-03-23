require 'spec_helper'
require 'prometheus/client/formats/text'

class SampleMetric
  def setup(registry, pubsub)
    registry.register(::Prometheus::Client::Gauge.new(
      :test_gauge,
      docstring: '...',
      labels: [:test_label]
    ))

    pubsub.subscribe("sample_test_gauge") do |payload|
      metric = registry.get(:test_gauge)
      metric.set(payload[:value], labels: payload[:labels])
    end
  end
end

describe Monitoring::Prometheus do
  let(:registry) {
    Monitoring::Prometheus.setup
    Monitoring::Prometheus.registry
  }

  it 'creates a valid registry and allows metrics' do
    gauge = registry.gauge(:foo, docstring: '...', labels: [:bar])
    gauge.set(21.534, labels: { bar: 'test' })

    expect(gauge.get(labels: { bar: 'test' })).to eql(21.534)
  end

  it 'can use Pub/Sub events to update metrics on the registry' do
    gauge = registry.gauge(:foo, docstring: '...', labels: [:bar])

    pub_sub = Monitoring::PubSub.instance
    pub_sub.subscribe("foo_event_name") do |payload|
      labels = {
        bar: payload[:bar]
      }
      gauge.set(payload[:value], labels: labels)
    end

    pub_sub.publish("foo_event_name", value: 100, bar: "omicron")
    expect(gauge.get(labels: { bar: "omicron" })).to eql(100.0)
  end

  context 'when given a list of metrics to setup' do
    before do
      @metric_obj = SampleMetric.new
      @registry = ::Prometheus::Client::Registry.new
      @mock_pubsub = double("Mock Monitoring::PubSub")
    end

    def prometheus_setup
      Monitoring::Prometheus.setup(
        registry: @registry,
        metrics: [ @metric_obj ],
        pubsub: @mock_pubsub
      )
    end

    it 'calls .setup for the metric class' do
      expect(@metric_obj).to receive(:setup).with(@registry, @mock_pubsub)
      prometheus_setup
    end

    it 'adds custom metric definitions to the global registry and subscribes to related Pub/Sub events' do
      expect(@mock_pubsub).to receive(:subscribe).with("sample_test_gauge")
      prometheus_setup

      sample_metric = @registry.get(:test_gauge)
      expect(sample_metric).not_to be_nil
    end
  end
end
