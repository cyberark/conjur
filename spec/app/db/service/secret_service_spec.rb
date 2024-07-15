# frozen_string_literal: true

require 'spec_helper'

describe DB::Service::SecretService do

  subject { described_class.instance }

  let(:account) { 'rspec' }
  let(:secret_id) { "#{account}:variable:data/my_secret"}
  let(:secret_value) { "my_password" }
  let(:owner_id) { "#{account}:user:my_admin" }

  before do
    Role.create(role_id: owner_id)
    Resource.create(resource_id: secret_id, owner_id: owner_id)
  end

  context 'Create and Update' do

    it 'update first secret' do
      subject.secret_value_change(secret_id, secret_value)

      expect(Secret[resource_id: secret_id].value).to eq(secret_value)
    end

    it 'update additional secret' do
      Secret.create(resource_id: secret_id, value: 'initial')

      subject.secret_value_change(secret_id, secret_value)

      expect(Secret.where(resource_id: secret_id).all.size).to eq(2)
      expect(Secret.where(resource_id: secret_id).order(Sequel.desc(:version)).first.value).to eq(secret_value)
    end

    it 'deletes from Redis' do
      expect(Rails.cache).to receive(:delete).with(secret_id)
      subject.secret_value_change(secret_id, secret_value)
    end

    it 'adds an event to event table' do
      allow(ENV).to receive(:[]).with('ENABLE_PUBSUB').and_return('true')
      subject.secret_value_change(secret_id, secret_value)
      events = Event.all
      expect(events.size).to eq(1)
      event = events[0]
      expect(event.event_type).to eq('conjur.secret.value.changed')
      event_value = JSON.parse(event.event_value)
      expect(event_value['specversion']).to eq('1.0')
      expect(event_value['branch']).to eq('data')
      expect(event_value['name']).to eq('my_secret')
      expect(event_value['version']).to eq(1)
      expect(event_value['value']).to eq(nil)
    end
  end

end
