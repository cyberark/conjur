# frozen_string_literal: true
require 'singleton'
class EventInput
  include Singleton
  # Should return event_type and event_value
  def get_event_input(operation, db_obj)
    raise NotImplementedError
  end

  protected

  def get_entity_type
    raise NotImplementedError
  end

  def get_event_type(operation)
    ['conjur', get_entity_type, operation].join('.')
  end
end
