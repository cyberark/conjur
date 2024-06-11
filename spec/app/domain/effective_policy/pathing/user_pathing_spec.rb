require 'spec_helper'

RSpec.describe(EffectivePolicy::UserPathing) do
  let(:pathing) { Class.new { include EffectivePolicy::UserPathing }.new }
  let(:res) do
    double(
      "Resource",
      identifier: 'testuser@rootpolicy-test',
      owner_id: 'cucumber:policy:rootpolicy/acme-adm',
      resource_id: 'cucumber:user:ali@rootpolicy-acme-adm'
    )
  end

  before do
    allow(pathing).to receive(:policy_for_user).and_return('rootpolicy/acme-adm')
  end

  describe '#user_full_id' do
    it 'returns the correct user full id' do
      expect(pathing.user_full_id(res)).to eq('cucumber:user:rootpolicy/acme-adm/testuser')
    end
  end

  describe '#user_identifier' do
    it 'returns the correct user identifier' do
      expect(pathing.user_identifier(res)).to eq('rootpolicy/acme-adm/testuser')
    end
  end

  describe '#user_id' do
    it 'returns the user name' do
      expect(pathing.user_id('ala@rootpolicy-acme-adm')).to eq('ala')
    end
  end

  describe '#user_path' do
    it 'returns the user path from the identifier' do
      expect(pathing.user_path('testuser@rootpolicy-test')).to eq('rootpolicy-test')
    end
  end

  describe '#user_account_and_kind' do
    it 'returns the account and kind of the user' do
      expect(pathing.user_account_and_kind('cucumber:user:ali@rootpolicy-acme-adm')).to eq('cucumber:user')
    end
  end
end
