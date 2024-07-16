require 'spec_helper'

RSpec.describe(EffectivePolicy::PolicyTree::GrantCache) do
  let(:grant_cache) { EffectivePolicy::PolicyTree::GrantCache.new(
    EffectivePolicy::PolicyTree::PolicyCache.new)
  }

  describe '#add' do
    let(:role_kind) { 'group' }
    let(:role_identifier) { 'rootpolicy/acme-adm/outer-adm/gali' }
    let(:res_kind) { 'user' }
    let(:res_identifier1) { 'rootpolicy/acme-adm/ala' }
    let(:res_identifier2) { 'rootpolicy/rot' }

    context 'when adding a new grant' do
      it 'adds a grant to the cache' do
        grant = grant_cache.add(role_kind, role_identifier, res_kind, res_identifier1)
        expect(grant_cache.grants[role_identifier]).to eq(grant)
        expect(grant.value["members"].first.value).to eq("/#{res_identifier1}")
      end
    end

    context 'when adding two grants with the same role but different resources' do
      it 'adds both grants to the cache' do
        grant_cache.add(role_kind, role_identifier, res_kind, res_identifier1)
        grant_cache.add(role_kind, role_identifier, res_kind, res_identifier2)
        grant = grant_cache.grants[role_identifier]
        expect(grant.value["members"].map(&:value)).to contain_exactly("/#{res_identifier1}", "/#{res_identifier2}")
      end
    end
  end
end
