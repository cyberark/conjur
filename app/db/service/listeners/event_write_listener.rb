# frozen_string_literal: true

module DB
  module Service
    module Listeners
      class EventWriteListener < AbstractWriteListener

        def notify(entity, operation, db_obj)
          event_input_creator = nil
          case entity
          when :secret
            event_input_creator = ::SecretEventInput.instance
          end

          if event_input_creator
            event_type, event_value = event_input_creator.get_event_input(operation, db_obj)
            Event.create_event(event_type: event_type, event_value: event_value)
          end
        end
      end
   end
  end
end
