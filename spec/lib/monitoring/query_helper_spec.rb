require 'monitoring/query_helper'

describe Monitoring::QueryHelper do
  let(:queryhelper) { Monitoring::QueryHelper.instance }

  it 'returns policy resource counts' do
    resource_counts = queryhelper.policy_resource_counts
    expect(resource_counts).not_to be_empty
  end

  it 'returns policy role counts' do
    role_counts = queryhelper.policy_role_counts
    expect(role_counts).not_to be_empty
  end

end
