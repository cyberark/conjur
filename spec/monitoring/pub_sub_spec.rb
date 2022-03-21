require 'rack/test'
require 'spec_helper'
require 'monitoring/pub_sub'

describe Monitoring::PubSub do
  include Rack::Test::Methods

  let(:pubsub) { Monitoring::PubSub.instance }

  it 'unsubscribes blocks from a named event' do
    expect { |block|
      # Assert that each #subscribe call produces a
      # unique subscriber to event "A".
      a_sub_1 = pubsub.subscribe("A", &block)
      a_sub_2 = pubsub.subscribe("A", &block)
      expect(a_sub_1).not_to equal(a_sub_2)

      pubsub.subscribe("B", &block)

      # Arg {e:1} will be yielded twice, once by each
      # unique subscriber to event "A".
      pubsub.publish("A", {e:1})
      pubsub.publish("B", {e:2})

      pubsub.unsubscribe("A")
      pubsub.publish("A", {e:3})
      pubsub.publish("B", {e:4})
    }
    .to yield_successive_args({e:1}, {e:1}, {e:2}, {e:4})
  end

  it 'receives only subscribed events, in order published' do
    expect { |block|
      names = [ "A", "B", "C" ]
      names.each { |name|
        pubsub.subscribe(name, &block)
      }

      pubsub.publish("B", {e:1})
      pubsub.publish("C", {e:2})
      pubsub.publish("D", {e:3})
      pubsub.publish("A", {e:4})
    }
    .to yield_successive_args({e:1}, {e:2}, {e:4})
  end

end
