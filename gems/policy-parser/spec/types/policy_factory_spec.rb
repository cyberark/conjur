require 'spec_helper.rb'

describe Conjur::PolicyParser::Types::PolicyFactory do

  subject(:records) { Conjur::PolicyParser::YAML::Loader.load policy}

  context "when policy factory doesn't specify a base" do
    let(:policy) { <<-POLICY
- !policy-factory
  id: my-factory
  template:
    - !variable test
POLICY
    }

    it "has a nil base" do
      expect(records.first.base).to be(nil)
    end
  end

  context "when policy factory specicies a base" do
    let(:policy) { <<-POLICY
- !policy test
- !policy-factory
  id: another-factory
  base: !policy test
  template:
    - !variable test2
POLICY
    }

    it "has the base policy set" do
      expect(records.second.base.id).to eq('test')
    end
  end
end
