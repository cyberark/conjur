# frozen_string_literal: true
require 'spec_helper'

def validate_result(result)
  expect(result.size).to eq(1)
  expect(result[0][:memberships][0].values).to eq({ role_id: group_id, admin_option: false })
  expect(result[0][:annotations][0]).to eq({ "name" => 'authn/api-key', "value" => 'true' })
end

describe ReplicationHandler do
  let(:account) { "rspec" }
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }


  context 'replicate hosts' do
    let(:host_id) {"#{account}:host:data/hostus"}
    let(:group_id) {"#{account}:group:data/groupus"}
    let(:scope) { Role.where(:role_id.like(account + ":host:data/%"))}

    before do
      init_slosilo_keys(account)
      create_host(host_id, admin_user)
      Role.create(role_id: group_id)
      RoleMembership.create(role_id: group_id, member_id: host_id, admin_option: false, ownership:false)
    end

    subject { Class.new{ include ReplicationHandler, Cryptography}.new }

    it 'returns host with its memberships and annotations' do
      result = subject.replicate_hosts(scope)
      validate_result(result)
    end

    it 'utilizes redis when atlantis flag is set' do
      allow(Rails.application.config.conjur_config).to receive(:try).with(:conjur_edge_is_atlantis).and_return(true)
      subject.replicate_hosts(scope)
      expect(Rails.cache).to receive(:read).and_call_original
      expect_any_instance_of(Role).to_not receive(:all_roles)
      result = subject.replicate_hosts(scope)
      validate_result(result)
    end
  end
end
