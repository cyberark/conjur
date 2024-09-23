# frozen_string_literal: true

require 'spec_helper'

describe DB::Service::Types::WorkloadType do
  subject { described_class.instance }
  let(:resource_id) { 'rspec:host:data/my_workload' }
  let(:owner_id) { 'rspec:user:my_admin' }
  let(:policy_id) { 'rspec:policy:data' }

  before do
    Role.create(role_id: owner_id)
  end

  describe '#delete' do
    it 'deletes the redis user for the resource' do
      resource = Resource.create(resource_id: resource_id, owner_id: owner_id)
      expect(subject).to receive(:delete_redis_user).with(resource_id)
      subject.delete(resource)
    end
  end


end
