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
