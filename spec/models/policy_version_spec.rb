# frozen_string_literal: true

require 'spec_helper'

describe PolicyVersion do
  describe '.current' do
    let!(:previous) do
      # create a policy before to make sure it doesn't get returned
      PolicyVersion.create(\
        policy: policy('previous'),
        role: owner,
        policy_text: '[]'
      )

      # force constraints run
      PolicyVersion.db.execute("""
        SET CONSTRAINTS ALL IMMEDIATE;
        SET CONSTRAINTS ALL DEFERRED;
      """)
    end

    it 'returns nil if no policy load is in progress' do
      expect(PolicyVersion.current).to_not be
    end

    it 'returns the currently loading policy version' do
      pv = PolicyVersion.create(\
        policy: policy('current'),
        role: owner,
        policy_text: '[]'
      )
      expect(PolicyVersion.current).to eq(pv)
    end
  end

  it "finalizes previously active policy version" do
    one = PolicyVersion.create(\
      policy: policy('one'),
      role: owner,
      policy_text: '[]'
    )
    two = PolicyVersion.create(\
      policy: policy('two'),
      role: owner,
      policy_text: '[]'
    )
    expect(one.refresh.finished_at).to be
    expect(two.refresh.finished_at).to_not be
  end

  let(:owner) { Role.create(role_id: 'spec:user:spec') }
  def policy name
    Resource.create(resource_id: "spec:policy:#{name}", owner: owner)
  end
end

