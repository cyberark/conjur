# frozen_string_literal: true

require 'spec_helper'

describe DB::Service::ResourceService do
  subject { described_class.instance }

  let(:resource_id) { 'rspec:variable:data/my_secret' }
  let(:owner_id) { 'rspec:user:my_admin' }
  let(:policy_id) { 'rspec:policy:data' }

  before do
    Role.create(role_id: owner_id)
    Resource.create(resource_id: policy_id, owner_id: owner_id)
  end

  describe '#create_resource' do
    context 'when resource is created successfully' do
      it 'creates a resource and returns it' do
        resource = subject.create_resource(resource_id, owner_id, policy_id)
        expect(resource).not_to be_nil
        expect(resource[:resource_id]).to eq(resource_id)
        expect(resource[:owner_id]).to eq(owner_id)
        expect(resource[:policy_id]).to eq(policy_id)
      end

      it 'calls VariableType create method if resource kind is variable' do
        allow(Resource).to receive(:create).and_return(double('Resource', kind: 'variable'))
        expect(DB::Service::Types::VariableType.instance).to receive(:create)
        subject.create_resource(resource_id, owner_id, policy_id)
      end
    end

  end

  describe '#delete_resource' do
    context 'when resource exists' do
      it 'deletes the resource and returns it' do
        resource = Resource.create(resource_id: resource_id, owner_id: owner_id, policy_id: policy_id)
        expect(DB::Service::Types::VariableType.instance).to receive(:delete)
        deleted_resource = subject.delete_resource(resource_id)
        expect(deleted_resource).to eq(resource)
        result = Resource[resource_id]
        expect(result).to be_nil
      end
    end

    context 'when resource does not exist' do
      it 'returns nil' do
        allow(::Resource).to receive(:[]).with(resource_id).and_return(nil)
        deleted_resource = subject.delete_resource(resource_id)
        expect(deleted_resource).to be_nil
      end
    end
  end

  describe "#events are created" do
    it "event when delete secret" do
      allow(Rails.application.config.conjur_config).to receive(:conjur_pubsub_enabled).and_return(true)

      Resource.create(resource_id: resource_id, owner_id: owner_id, policy_id: policy_id)
      expect(Rails.cache).to receive(:delete).with("secrets/resource/#{resource_id}")
      expect(Rails.cache).to receive(:delete).with("#{resource_id}")
      subject.delete_resource(resource_id)
      resource = Resource[resource_id]
      expect(resource).to be_nil
      events = Event.all
      expect(events.size).to eq(1)
      event = events[0]
      expect(event.event_type).to eq('conjur.secret.deleted')
      event_value = JSON.parse(event.event_value)
      expect(event_value['specversion']).to eq('1.0')
      expect(event_value['data']['branch']).to eq('data')
      expect(event_value['data']['name']).to eq('my_secret')

    end
    it  "event when create secret" do
      allow(Rails.application.config.conjur_config).to receive(:conjur_pubsub_enabled).and_return(true)
      subject.create_resource(resource_id, owner_id, policy_id)
      events = Event.all
      resource = Resource[resource_id]
      expect(resource).not_to be_nil
      expect(events.size).to eq(1)
      event = events[0]
      expect(event.event_type).to eq('conjur.secret.created')
      event_value = JSON.parse(event.event_value)
      expect(event_value['specversion']).to eq('1.0')
      expect(event_value['data']['branch']).to eq('data')
      expect(event_value['data']['name']).to eq('my_secret')
      expect(event_value['data']['owner']['kind']).to eq('user')
      expect(event_value['data']['owner']['id']).to eq('my_admin')
    end
  end
end