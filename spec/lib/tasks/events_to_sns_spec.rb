require 'spec_helper'
Rails.application.load_tasks

describe "events_to_sns:publish" do

  before(:each) do
    create_sns_topic
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ENABLE_PUBSUB').and_return('true')
  end

  it "runs the MessageJob and logs errors if any" do
    expect(MessageJob.instance).to receive(:run)
    transaction_id = nil
    thread = Thread.new do
      event1 = Event.create_event(event_type: 'test_event1', event_value: '{"key":"value1"}')
      # Event.create_event(event_type: 'test_event2', event_value: '{"key":"value2"}')
      transaction_id = event1[:transaction_id]
      expect(Event.where(transaction_id: transaction_id).count).to eq(1)
      Rake::Task["events_to_sns:publish"].invoke

    end

    # Rake::Task["events_to_sns:publish"].invoke
    thread.join if thread # Ensure the thread completes execution
    expect(Event.where(transaction_id: transaction_id).count).to eq(0)
  end

  it "logs an error if MessageJob fails" do
    allow(MessageJob.instance).to receive(:run).and_raise(StandardError.new("Test error"))
    Rake::Task["events_to_sns:publish"].invoke
  end
end