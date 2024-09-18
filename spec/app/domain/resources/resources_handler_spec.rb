require 'spec_helper'

describe ResourcesHandler do
  include ResourcesHandler

  context 'Parsing resource id' do
    valid_name_id = 'conjur:variable:myvariable' 
    valid_branch_id = 'conjur:variable:branch1/branch2/myvariable' 
    invalid_more_segment_id = 'conjur:variable:branch1:branch2/myvariable' 
    invalid_less_segement_id = 'conjur:branch1/branch2/myvariable'

    it 'parses resource id sucssefully' do
      expect(parse_resource_id(valid_name_id)).to eq({ account: 'conjur', type: 'variable', branch: 'root', name: 'myvariable', id: 'myvariable' })
      expect(parse_resource_id(valid_name_id, v2_syntax: true)).to eq({ account: 'conjur', type: 'secret', branch: 'root', name: 'myvariable', id: 'myvariable' })
      expect(parse_resource_id(valid_branch_id)).to eq({ account: 'conjur', type: 'variable', branch: 'branch1/branch2', name: 'myvariable', id: 'branch1/branch2/myvariable' })
      expect(parse_resource_id(valid_branch_id, v2_syntax: true)).to eq({ account: 'conjur', type: 'secret', branch: 'branch1/branch2', name: 'myvariable', id: 'branch1/branch2/myvariable' })
    end
    it 'throw error when resource id is not excatly 3 segments' do
      expect { parse_resource_id(invalid_more_segment_id) }.to raise_error(Exceptions::InvalidResourceId)
      expect { parse_resource_id(invalid_less_segement_id) }.to raise_error(Exceptions::InvalidResourceId)
      expect { parse_resource_id(nil) }.to raise_error(Exceptions::InvalidResourceId)
    end
  end
end
