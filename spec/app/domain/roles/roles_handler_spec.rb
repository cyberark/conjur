require 'spec_helper'

describe RolesHandler do
  include RolesHandler 

  context 'Parsing role id' do
    valid_name_id = 'conjur:user:my_user'
    valid_branch_id = 'conjur:host:internal/system:service:user-000:L'
    invalid_more_segment_id = 'conjur:branch2/myvariable' 
    invalid_less_segement_id = 'conjur:branch1/branch2/myvariable' 

    it 'parses resource id sucssefully' do
      expect(parse_role_id(valid_name_id)).to eq({ account: 'conjur', type: 'user',  id: 'my_user' })
      expect(parse_role_id(valid_name_id, v2_syntax: true)).to eq({ account: 'conjur', type: 'user',  id: 'my_user' })
      expect(parse_role_id(valid_branch_id)).to eq({ account: 'conjur', type: 'host', id: 'internal/system:service:user-000:L' })
      expect(parse_role_id(valid_branch_id, v2_syntax: true)).to eq({ account: 'conjur', type: 'workload', id: 'internal/system:service:user-000:L' })
    end
    it 'throw error when resource id is not excatly 3 segments' do
      expect { parse_role_id(invalid_more_segment_id) }.to raise_error(Exceptions::InvalidRoleId)
      expect { parse_role_id(invalid_less_segement_id) }.to raise_error(Exceptions::InvalidRoleId)
      expect { parse_role_id(nil) }.to raise_error(Exceptions::InvalidRoleId)
    end
  end
end
