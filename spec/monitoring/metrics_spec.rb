require 'rack/test'
require 'prometheus/client/formats/text'
require 'monitoring/prometheus'
require 'monitoring/pub_sub'

describe Monitoring::Prometheus do
  include Rack::Test::Methods

  before do
    Monitoring::Prometheus.setup(registry: Prometheus::Client::Registry.new)
    @registry = Monitoring::Prometheus.registry
  end

  it 'creates a valid registry and allows metrics' do
    gauge = @registry.gauge(:foo, docstring: '...', labels: [:bar])
    gauge.set(21.534, labels: { bar: 'test' })

    expect(gauge.get(labels: { bar: 'test' })).to eql(21.534)
  end

  it 'can use Pub/Sub events to update metrics on the registry' do
    gauge = @registry.gauge(:foo, docstring: '...', labels: [:bar])

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
end
