require 'monitoring/query_helper'
require 'spec_helper'

RSpec.describe Monitoring::QueryHelper do
  describe '#policy_resource_counts' do
    it 'returns the correct resource counts' do
      allow(Resource).to receive(:group_and_count).and_return([
        { kind: 'resource1', count: 10 },
        { kind: 'resource2', count: 20 }
      ])

      counts = Monitoring::QueryHelper.instance.policy_resource_counts

      expect(counts).to eq({ 'resource1' => 10, 'resource2' => 20 })
    end

    it 'returns an empty hash if there are no resources' do
      allow(Resource).to receive(:group_and_count).and_return([])

      counts = Monitoring::QueryHelper.instance.policy_resource_counts

      expect(counts).to eq({})
    end
  end

  describe '#policy_visible_resource_counts' do
    it 'returns the correct visible_resource counts' do
      allow(Issuer).to receive(:where).and_return([
        { issuer: 'myissuer1'},
        { issuer: 'myissuer2'},
        { issuer: 'myissuer3'}
      ])

      allow(HostFactoryToken).to receive(:count).and_return(3)

      allow(Resource).to receive(:where).with(
        Sequel.like(:resource_id, 'conjur:variable:' + Issuer::DYNAMIC_VARIABLE_PREFIX + '%')).and_return([
          { secret: 'secret1'},
          { secret: 'secret2'}
      ])
      allow(Resource).to receive(:where).with(
        Sequel.like(:resource_id, '%conjur:variable:data/%')).and_return([
          { secret: 'secret1'},
          { secret: 'secret2'},
          { secret: 'secret3'},
          { secret: 'secret4'}
      ])
      allow(Resource).to receive(:where).with(
        Sequel.like(:resource_id, '%conjur:host:data/%')).and_return([
          { secret: 'host1'},
          { secret: 'host2'}
      ])

      allow(Resource).to receive(:where).with(
        Sequel.like(:resource_id, '%conjur:user:%')).and_return([
          { secret: 'user1'}
      ])

      counts = Monitoring::QueryHelper.instance.policy_visible_resource_counts

      expect(counts).to eq({ 'issuers' => 3, 'dynamic-secrets' => 2, "host-factory"=>3, 'secrets' => 4, 'workloads' => 2, 'users' => 1 })
    end

    it 'returns zero-valued hash if there are no resources' do
      allow(Resource).to receive(:group_and_count).and_return([])
      allow(HostFactoryToken).to receive(:count).and_return(7)

      counts = Monitoring::QueryHelper.instance.policy_visible_resource_counts

      expect(counts).to eq({"dynamic-secrets"=>0, "host-factory"=>7, "issuers"=>0, "secrets"=>0, "users"=>0, "workloads"=>0 }   )
    end
  end

  describe '#policy_role_counts' do
    it 'returns the correct role counts' do
      allow(Role).to receive(:group_and_count).and_return([
        { kind: 'role1', count: 5 },
        { kind: 'role2', count: 15 }
      ])

      counts = Monitoring::QueryHelper.instance.policy_role_counts

      expect(counts).to eq({ 'role1' => 5, 'role2' => 15 })
    end

    it 'returns an empty hash if there are no roles' do
      allow(Role).to receive(:group_and_count).and_return([])

      counts = Monitoring::QueryHelper.instance.policy_role_counts

      expect(counts).to eq({})
    end
  end
end
