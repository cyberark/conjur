# frozen_string_literal: true
require 'singleton'
class EventInput
  include Singleton
  # Should return event_type and event_value
  def get_event_input(operation, db_obj)
    raise NotImplementedError
  end

  # Generates event input based on specific implementation of `get_event_input` in derived class
  # And creates event based on that input
  def send_event(operation, db_obj)
    if ENV['ENABLE_PUBSUB'] == 'true'
      event_type, event_value = get_event_input(operation, db_obj)
      Event.create_event(event_type: event_type, event_value: event_value)
    end
  end

  protected

  def get_entity_type
    raise NotImplementedError
  end

  def get_event_type(operation)
    ['conjur', get_entity_type, operation].join('.')
  end
end
