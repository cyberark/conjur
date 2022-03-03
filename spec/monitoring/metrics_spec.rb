require 'rack/test'
require 'prometheus/client/formats/text'
require 'monitoring/prometheus'

describe Monitoring::Prometheus do
  include Rack::Test::Methods

  it 'creates a valid registry and allows metrics' do
    Monitoring::Prometheus.setup(registry: Prometheus::Client::Registry.new)
    gauge = Monitoring::Prometheus.registry.gauge(:foo, docstring: '...', labels: [:bar])
    gauge.set(21.534, labels: { bar: 'test' })

    expect(gauge.get(labels: { bar: 'test' })).to eql(21.534)
  end
end
