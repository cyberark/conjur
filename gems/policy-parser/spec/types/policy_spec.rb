require 'spec_helper'

describe Conjur::PolicyParser::Types::Policy do
  let(:policy) do 
    <<~POLICY
      - !policy
        account: an-account
        id: a-policy
        owner: !role
          account: an-account
          id: policy-owner
          kind: user
        annotations:
          an-annotation: a-value
    POLICY
  end
  
  it 'sets annotations on the policy Resource' do
    records = Conjur::PolicyParser::YAML::Loader.load(policy)
    expect(records.first.resource.annotations).not_to be(nil)
  end
  
end
