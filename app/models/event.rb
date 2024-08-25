# frozen_string_literal: true

class Event < Sequel::Model


  class << self

    def create_event(event_type:, event_value:)
      begin
        Event.create(event_type: event_type, event_value: event_value)
      rescue Sequel::DatabaseError => e
        if e.cause.is_a?(PG::InvalidTextRepresentation)
          error_msg = "create_event failed on invalid input. event_value must be a valid json. " + e.message
          Rails.logger.error(error_msg)
          raise ApplicationController::InternalServerError, error_msg
        else
          raise ApplicationController::InternalServerError, e.message
        end
      end
    end

    # Returns all events grouped by transaction_id and sorted by event_id
    # e.g. {{trans1: [{event1}, {events}]}, {trans2}: [{event3}], ...}
    def get_all_events_grouped
      db_result = Event.order(:event_id).all

      # Transform to Ruby objects
      ruby_pairs = []
      db_result.each do |row|
        ruby_pairs << [row[:transaction_id], row]
      end
      ruby_pairs.group_by(&:first).transform_values { |values| values.map(&:last) }
    end

    # @param: event_id can be either a single id or an array of ids
    def delete_by_id(event_id)
      Event.where(event_id: event_id).delete
    end

    def delete_by_transaction_id(transaction_id)
      Event.where(transaction_id: transaction_id).delete
    end

    def unique_transaction_ids_count
      Event.distinct.count(:transaction_id)
    end
  end
end
