# frozen_string_literal: true
require 'spec_helper'

describe Event, :type => :model do

  context "Create" do
    it "create event successfully" do
      event_object = Event.create_event(event_type: 'create', event_value: "{\"id\": \"var1\"}")
      expect(event_object[:event_type]).to eq('create')
      expect(event_object[:event_value]).to eq("{\"id\": \"var1\"}")
      expect(event_object[:created_at]).to be
    end

    it "Create event invalid event_value" do
      expect(Rails.logger).to receive(:error).with(include("create_event failed"))
      expect { Event.create_event(event_type: 'create', event_value: "non json") }.to raise_error(ApplicationController::InternalServerError)
    end

    it "sets created_at automatically" do
      event_object = Event.create_event(event_type: 'create', event_value: "{\"id\": \"var1\"}")
      expect(event_object[:created_at]).to be_within(1.second).of(Time.now)
    end

    it "auto sets transaction_id via trigger" do
      event = Event.create_event(event_type: 'create', event_value: "{\"id\": \"var3\"}")
      expect( event[:transaction_id].to_i).to be > 0
    end

  end

  context 'Get grouped events' do
    it 'Create events in same transaction' do
      Event.create_event(event_type: 'create', event_value: "{\"id\": \"var1\"}")
      Event.create_event(event_type: 'delete', event_value: "{\"id\": \"var2\"}")
      Event.create_event(event_type: 'update', event_value: "{\"id\": \"var3\"}")

      # Group events by transaction_id
      events_grouped = Event.get_all_events_grouped

      # Check that the number of grouped transaction_ids is 1
      expect(events_grouped.size).to eq(1)
    end

    it 'creates two events in two transactions and groups them correctly' do
      event4 = Event.create_event(event_type: 'create', event_value: "{\"id\": \"var1\"}")
      event5 = Event.create_event(event_type: 'create', event_value: "{\"id\": \"var1\"}")

      # Update the transaction_id for both events
      event4.update(transaction_id: "100")
      event5.update(transaction_id: "101")
      events_grouped = Event.get_all_events_grouped

      expect(events_grouped.size).to eq(2)
      # verify that events_grouped is sorted by min event_id
      mins = events_grouped.values.map { |events| events.map{|e| e[:event_id]}.min }
      expect(mins).to eq(mins.sort)
    end
  end


  context "delete events" do
    before do
      Event.create(event_type: 'delete', event_value: "{}")
      Event.create(event_type: 'update', event_value: "{}")
      Event.create(event_type: 'create', event_value: "{}")
      Event.create(event_type: 'update', event_value: "{}")
      Event.create(event_type: 'create', event_value: "{}")
    end

    it "delete by event id" do
      event_id = Event.last[:event_id]
      Event.delete_by_id(event_id)
      remaining_events = Event.all
      expect(remaining_events.size).to eq(4)
      remaining_events.each{|event| expect(event[:event_id]).to_not eq(event_id)}
    end

    it "delete by multiple event ids" do
      event_ids = Event.dataset.select(:event_id).limit(2).all.map{|e| e[:event_id]}
      Event.delete_by_id(event_ids)
      remaining_events = Event.all.map{|e| e[:event_id]}
      expect(remaining_events.size).to eq(3)
      # Check there is no id belonging to both event_ids and remaining_ids
      expect((event_ids & remaining_events).empty?).to be(true)
    end

    it "delete by transaction id" do
      transaction_id = Event.last[:transaction_id]
      Event.delete_by_transaction_id(transaction_id)
      remaining_events = Event.all
      expect(remaining_events.size).to eq(0)
    end
  end
end
