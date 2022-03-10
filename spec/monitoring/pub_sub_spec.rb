require 'rack/test'
require 'spec_helper'
require 'monitoring/pub_sub'

describe Monitoring::PubSub do
  include Rack::Test::Methods

  let(:name) { "test_metric" }
  let(:test_payload) { { code: 200, path: "/foo/path", duration: 1.0 } }

  context 'when using mocked ActiveSupport::Notifications' do
    let(:mock_notifications) { double("Mock ActiveSupport::Notifications") }
    let(:pubsub) { Monitoring::PubSubBase.new(mock_notifications) }

    it 'publishes named events with a given payload' do
      expect(mock_notifications).to receive(:instrument).with(name, test_payload)

      pubsub.publish(name, test_payload)
    end

    it 'subscribes blocks to named events which operate on a payload' do
      expect(mock_notifications).to receive(:subscribe)
        .with(name)
        .and_yield(nil, nil, nil, nil, test_payload)

      to_update = nil
      pubsub.subscribe(name) do |payload|
        to_update = payload
      end

      expect(to_update).to eql(test_payload)
    end

    it 'unsubscribes blocks from named events' do
      expect(mock_notifications).to receive(:unsubscribe).with(name)

      pubsub.unsubscribe(name)
    end
  end

  context 'when using ActiveSupport::Notifications end-to-end' do
    let(:pubsub) { Monitoring::PubSubBase.new }

    it 'subscribes to, publishes, and unsubscribes from events' do
      publish_counter = 0
      pubsub.subscribe(name) do |payload|
        publish_counter += 1
      end

      expect(publish_counter).to eql(0)
      pubsub.publish(name)
      expect(publish_counter).to eql(1)

      pubsub.unsubscribe(name)
      pubsub.publish(name)
      expect(publish_counter).to eql(1)
    end
  end
end
