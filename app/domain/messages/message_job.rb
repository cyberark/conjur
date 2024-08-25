# frozen_string_literal: true
require 'singleton'
require_relative '../aws/sns_client'
class MessageJob
  include Singleton

  @logger

  def initialize
    @logger = Rails.logger
    @message_version = '1.0'
  end

  def run
    return unless Rails.application.config.conjur_config.try(:conjur_pubsub_enabled)
    unique_transaction_ids_count_value = Event.unique_transaction_ids_count
    return if unique_transaction_ids_count_value.zero?
    Sequel::Model.db.transaction do
      Sequel::Model.db.run("SET idle_in_transaction_session_timeout = '#{timeout_value(unique_transaction_ids_count_value)}s';")
      lock_acquired = acquire_lock
      handle_process_message(lock_acquired)
    end
  end

  private

  def handle_process_message(lock_acquired)
    if lock_acquired
      @logger.debug("Acquired lock with id #{get_lock_identifier}, starting processing message.")
      process_message
    else
      @logger.debug("Could not acquire lock with id #{get_lock_identifier}")
    end
  end

  # lock releases in the transaction end
  def acquire_lock
      Sequel::Model.db.fetch("SELECT pg_try_advisory_xact_lock(:lock_id) AS lock_acquired;", lock_id: get_lock_identifier).first[:lock_acquired]
  end

  def process_message
    grouped_events = Event.get_all_events_grouped
    grouped_events.each do |transaction_id, events|
      filled_events_with_value = fill_events_hash(events)
      events_chunks = split_events_into_json_chunks_recursive(filled_events_with_value)
      send_message(events_chunks, transaction_id)
      delete_by_events_id(map_to_ids(events))
    end
  end

  def send_message(events_chunks, transaction_id)
    number_of_messages = events_chunks.size
    events_chunks.each_with_index do |message, index|
      message_attributes = {
        "source" => {
          data_type: "String",
          string_value: "Conjur" # This is default value for conjur service
        },
        "id" => {
          data_type: "String",
          string_value: transaction_id.to_s
        },
        "version" => {
          data_type: "String",
          string_value: @message_version
        },
        "Parts" => {
          data_type: "Number",
          string_value: number_of_messages.to_s
        },
        "PartNumber" => {
          data_type: "Number",
          string_value: (index + 1).to_s
        },
        "tenant_id" => {
          data_type: "String",
          string_value: ENV['TENANT_ID']
        },
        "time" => {
          data_type: "String",
          string_value: Time.now.utc.iso8601(3).to_s
        }
      }
      SnsClient.instance.publish(message, message_attributes)
    end
  end

  # return timeout value in seconds
  def timeout_value(id_count)
    id_count * 30
  end

  def fill_events_hash(events)
    filled_events = []
    events.each do |event|
      value_hash = JSON.parse(event[:event_value])
      value_hash['id'] = event[:event_id].to_s
      value_hash['time'] = event[:created_at].iso8601(3)
      value_hash['type'] = event[:event_type]
      filled_events.append(value_hash)
    end
    filled_events
  end

  # I take in to account that a single event never exceeds the max size
  def split_events_into_json_chunks_recursive(events, max_size_kb = 120)
    json_str = events_json(events)
    if json_str.bytesize <= max_size_kb * 1024
      return [json_str]
    else
      if events.size == 1
        original_event = events.first
        error_event = {
          'id' => original_event['id'],
          'time' => original_event['time'],
          'type' => original_event['type'],
          'message_error' => 'Event size exceeds the maximum allowed size'
        }
        @logger.error("Event with id #{original_event['id']} exceeds the maximum allowed size of #{max_size_kb}KB")
        return [events_json([error_event])]
      end
      mid_index = events.size / 2
      left_chunks = split_events_into_json_chunks_recursive(events[0...mid_index], max_size_kb)
      right_chunks = split_events_into_json_chunks_recursive(events[mid_index..-1], max_size_kb)
      return left_chunks + right_chunks
    end
  end

  def events_json(filled_events)
    { "events": filled_events }.to_json
  end

  def map_to_ids(events)
    events.map { |event| event[:event_id] }
  end

  def delete_by_events_id(events_ids)
    Event.delete_by_id(events_ids)
  end

  def get_lock_identifier
    ENV['TENANT_ID'].to_i(36)
  end
end
