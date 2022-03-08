require 'rack/test'
require 'spec_helper'
require 'monitoring/pub_sub'
require 'monitoring/prometheus'

describe Monitoring::PubSub do
  include Rack::Test::Methods

  before do
    # Set up global Prometheus registry
    Monitoring::Prometheus::setup(registry: Prometheus::Client::Registry.new)
    counter = Monitoring::Prometheus.registry.counter(
      :test_metric,
      docstring: '...',
      labels: [:path, :code]
    )

    # Subscribe code blocks to events
    Monitoring::PubSub.subscribe('end_to_end_metric') do
      counter.increment(labels: { path: '/test/path', code: 200 })
      counter.increment(labels: { path: '/test/path', code: 500 })
    end
    Monitoring::PubSub.subscribe('payload_metric') do |payload|
      path = payload[:path]
      code = payload[:code]
      counter.increment(labels: { path: path, code: code })
    end
  end

  context 'when an event is published' do
    it 'executes the subscribed code block, and updates metrics in the registry' do
      Monitoring::PubSub.publish('end_to_end_metric')

      counter = Monitoring::Prometheus.registry.get(:test_metric)
      expect(counter.get(labels: { path: '/test/path', code: 200 })).to eql(1.0)
      expect(counter.get(labels: { path: '/test/path', code: 500 })).to eql(1.0)
    end
  end

  context 'when an event with a payload is published' do
    it 'executes the subscribed code block and processes the payload' do
      Monitoring::PubSub.publish('payload_metric', path: '/payload/path', code: 401)

      counter = Monitoring::Prometheus.registry.get(:test_metric)
      expect(counter.get(labels: { path: '/payload/path', code: 401 })).to eql(1.0)
    end
  end

end
