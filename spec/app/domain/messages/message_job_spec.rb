# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MessageJob do

  let(:message_job) { MessageJob.instance }

  before(:all) do
    ENV['ENABLE_PUBSUB'] = 'true'
  end
  before(:each) do
    create_sns_topic
  end

  after(:each) do
    delete_sns_topic
  end

  describe '#fill_events_hash' do
    it 'fills the event hash with additional fields' do
      events = [
        { event_id: 1, created_at: Time.now, event_type: 'conjur.secret.created', event_value: '{"key":"value1"}' },
        { event_id: 2, created_at: Time.now, event_type: 'conjur.host.created', event_value: '{"key":"value2"}' }
      ]

      filled_events = message_job.send(:fill_events_hash, events)
      expect(filled_events).to all(include('id', 'time', 'type'))
      expect(filled_events.first['id']).to eq(events.first[:event_id])
      expect(filled_events.first['type']).to eq(events.first[:event_type])
      expect(filled_events.first['time']).to eq(events.first[:created_at].iso8601(3))
    end
  end

  describe '#events_json' do
    it 'converts an array of filled events into a JSON string' do
      # Setup
      filled_events = [
        { 'id' => 1, 'time' => '2023-04-01T12:00:00.000Z', 'type' => 'event_type1', 'key' => 'value1' },
        { 'id' => 2, 'time' => '2023-04-02T13:00:00.000Z', 'type' => 'event_type2', 'key' => 'value2' }
      ]
      expected_json = '{"events":[{"id":1,"time":"2023-04-01T12:00:00.000Z","type":"event_type1","key":"value1"},{"id":2,"time":"2023-04-02T13:00:00.000Z","type":"event_type2","key":"value2"}]}'

      # Execution
      result_json = message_job.send(:events_json, filled_events)

      # Assertion
      expect(result_json).to eq(expected_json)
    end
  end
  describe '#check events delete and mapping to array integer' do
    it 'deletes event by event_id' do
      # Setup
      event1 = Event.create_event(event_type: 'test_event', event_value: '{"key":"value"}')
      Event.create_event(event_type: 'test_event2', event_value: '{"key":"value"}')

      message_job.send(:delete_by_events_id, event1[:event_id])

      # Assertion
      expect(Event.count).to eq(1)
    end
    it 'deletes multiple events by their event_ids' do
      # Setup: Create multiple events
      event1 = Event.create_event(event_type: 'multi_test_event1', event_value: '{"key":"value1"}')
      event2 = Event.create_event(event_type: 'multi_test_event2', event_value: '{"key":"value2"}')
      event3 = Event.create_event(event_type: 'multi_test_event3', event_value: '{"key":"value3"}')

      # Delete some of the events by passing their event_ids in an array
      message_job.send(:delete_by_events_id, [event1[:event_id], event3[:event_id]])

      # Assertion: Check that only the non-deleted event remains
      expect(Event.count).to eq(1)
      expect(Event.first[:event_id]).to eq(event2[:event_id])
    end

    it 'map to array of ints' do
      event1 = Event.create_event(event_type: 'multi_test_event1', event_value: '{"key":"value1"}')
      event2 = Event.create_event(event_type: 'multi_test_event2', event_value: '{"key":"value2"}')
      event3 = Event.create_event(event_type: 'multi_test_event3', event_value: '{"key":"value3"}')

      ids = message_job.send(:map_to_ids, [event1, event2, event3])

      expect(ids.size).to eq(3)
    end

    it 'map to array of ints' do
      event1 = Event.create_event(event_type: 'multi_test_event1', event_value: '{"key":"value1"}')

      ids = message_job.send(:map_to_ids, [event1])

      expect(ids.size).to eq(1)
    end
  end
  describe '#run' do
    it 'processes and deletes events grouped by transaction_id' do
      # Setup: Create events grouped by a transaction_id
      event1 = Event.create_event(event_type: 'test_event1', event_value: '{"key":"value1"}')
      Event.create_event(event_type: 'test_event2', event_value: '{"key":"value2"}')

      transaction_id = event1[:transaction_id]
      # Ensure events are present before running the method
      expect(Event.where(transaction_id: transaction_id).count).to be > 0

      # Execution: Run the method
      MessageJob.instance.run

      # Assertion: Check that events are deleted
      expect(Event.where(transaction_id: transaction_id).count).to eq(0)
    end
  end
  describe 'check locking' do
    # it 'fails to acquire lock when another transaction holds it' do
    #   allow(Event).to receive(:unique_transaction_ids_count).and_return(5)
    #   # Override the process_message method to include sleep
    #   allow_any_instance_of(MessageJob).to receive(:process_message) do
    #     sleep(5) # Simulates long processing time
    #   end
    #
    #   # Start the first job in a thread
    #   thread1 = Thread.new do
    #
    #     message_job.run
    #   end
    #   sleep(1) # Ensure the first job starts and acquires the lock before starting the second job
    #
    #   # Attempt to start the second job in another thread
    #   #
    #   lock_acquired_value = nil
    #   thread2 = Thread.new do
    #     message_job.run
    #     lock_acquired_value = Sequel::Model.db.fetch("SELECT pg_try_advisory_xact_lock(:lock_id) AS lock_acquired;", lock_id: MessageJob.instance.send(:get_lock_identifier)).first[:lock_acquired]
    #   end
    #
    #   thread1.join
    #   thread2.join
    #   expect(lock_acquired_value).to be false
    # end

    # it 'successfully acquires lock after the first transaction completes' do
    #   # Setup: Ensure necessary data is present
    #
    #   # Override the process_message method to include sleep
    #   allow_any_instance_of(MessageJob).to receive(:process_message) do
    #     sleep(5) # Simulates long processing time
    #   end
    #
    #   # Start the first job in a thread and wait for it to complete
    #   thread1 = Thread.new do
    #     MessageJob.instance.run
    #   end
    #   thread1.join # Wait for the first thread to finish
    #
    #   # Start the second job in another thread and capture the lock_acquired value
    #   lock_acquired_value = nil
    #   thread2 = Thread.new do
    #     MessageJob.instance.run
    #     lock_acquired_value = Sequel::Model.db.fetch("SELECT pg_try_advisory_xact_lock(:lock_id) AS lock_acquired;", lock_id: MessageJob.instance.send(:get_lock_identifier)).first[:lock_acquired]
    #   end
    #   thread2.join
    #
    #   # Assert that the second job's attempt to acquire the lock succeeded
    #   expect(lock_acquired_value).to be true
    # end

  end
  describe '#get_lock_identifier' do
    it 'returns the correct lock identifier based on TENANT_ID' do
      # Calculate the expected lock identifier
      sha256_hash = Digest::SHA256.hexdigest(ENV['TENANT_ID'])
      bigint_max = 9223372036854775807
      expected_lock_identifier = sha256_hash[0...16].to_i(16) % (bigint_max + 1)
      # Adjust if the result is negative, to ensure it's within the positive range of bigint
      expected_lock_identifier += bigint_max + 1 if expected_lock_identifier < 0


      # Call the method and get the lock identifier
      lock_identifier = message_job.send(:get_lock_identifier)

      # Assert that the returned lock identifier matches the expected value
      expect(lock_identifier).to eq(expected_lock_identifier)
    end
  end

  def create_events_values_until_size_exceeds(size = 2)
    event_type = 'test_event'
    base_event_value = '{"key":"value"}'
    total_size = 0
    events = []

    while total_size <= size * 1024
      event = Event.create_event(event_type: event_type, event_value: base_event_value)
      events << message_job.send(:fill_event_hash,event)
      total_size += base_event_value.bytesize
    end

    events
  end



  describe '#split_events_into_json_chunks' do
    let(:event) { { event_value: 'Small event' }.to_json }

    it 'splits large events into multiple chunks' do
      filled_events_value = create_events_values_until_size_exceeds(2)
      # filled_events = message_job.send(:fill_events_hash,events)
      max_size = 1.5
      chunks = message_job.send(:split_events_into_json_chunks_recursive, filled_events_value, max_size)
      expect(chunks.size).to be > 1
      chunks.each do |chunk|
             expect(chunk.bytesize).to be <= max_size * 1024
      end
    end


    it 'returns a single chunk for small events' do
      event_type = 'test_event'
      event1 = Event.create_event(event_type: event_type, event_value: '{"key":"value"}')
      event2 = Event.create_event(event_type: event_type, event_value: '{"key":"value"}')
      max_size = 2
      filled_events_value = message_job.send(:fill_events_hash,[event1,event2])
      chunks = message_job.send(:split_events_into_json_chunks_recursive, filled_events_value,max_size)
      expect(chunks.size).to eq(1)
    end

    it 'splits large events into multiple chunks and adds an error event if a single event exceeds the max size' do
      # Create a large event with size greater than 1 KB
      filled_events_value = create_events_values_until_size_exceeds(2)
      large_event_value = { 'key' => 'a' * 1025 }.to_json # Ensure the value is in JSON format
      event_type = 'test_event'
      large_event = Event.create_event(event_type: event_type, event_value: large_event_value)
      filled_event = message_job.send(:fill_event_hash, large_event)
      filled_events_value << filled_event

      chunks = message_job.send(:split_events_into_json_chunks_recursive, filled_events_value, 1)


      expect(chunks.size).to be > 1

      error_event = JSON.parse(chunks.last)['events'].last
      expect(error_event.keys).to contain_exactly('id', 'time', 'type', 'message_error')
      expect(error_event['message_error']).to eq('Event size exceeds the maximum allowed size')
      expect(error_event['id']).to eq(filled_event['id'])
      expect(error_event['time']).to eq(filled_event['time'])
      expect(error_event['type']).to eq(filled_event['type'])
    end


  end

  describe "#check messages send to sns and deleted" do
    let(:sqs_client) { Aws::SQS::Client.new }
    let(:queue_arn) do
      create_sqs_queue
    end

    before(:each) do
      SnsClient.instance.sns_client.subscribe(topic_arn: ENV['TOPIC_ARN'], protocol: 'sqs', endpoint: queue_arn)
    end

    after(:each) do
      delete_sqs_queue
    end
    it 'processes and deletes events grouped by transaction_id' do
      # Setup: Create events grouped by a transaction_id
      Event.create_event(event_type: 'test_event1', event_value: '{"key":"value1"}')
      Event.create_event(event_type: 'test_event2', event_value: '{"key":"value2"}')


      # Execution: Run the method
      MessageJob.instance.run
      received_message = nil
      Timeout.timeout(10) do
        loop do
          messages = sqs_client.receive_message(queue_url: ENV['QUEUE_URL'], max_number_of_messages: 1).messages
          unless messages.empty?
            received_message = messages.first.body
            break
          end
          sleep 1
        end
      end

      parsed_message = JSON.parse(received_message)
      message_body =  JSON.parse(parsed_message['Message'])
      expect(message_body['events'].size).to eq(2)

    end
  end
end