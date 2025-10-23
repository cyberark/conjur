# spec/domain/membership/membership_service_spec.rb
require 'spec_helper'

RSpec.describe(Memberships::MembershipService, type: :service) do
  let(:res_service) { instance_double(Resources::ResourceService) }
  let(:role_membership_repo) { class_double(RoleMembership) }
  let(:logger) { instance_double(Logger, debug?: false, info: nil, error: nil) }
  
  let(:service) do
    described_class.send(:new,
                         res_service: res_service,
                         role_membership_repo: role_membership_repo,
                         logger: logger)
  end

  let(:current_user) { instance_double(Role, id: 'user:admin') }
  let(:account) { 'test-account' }
  let(:group_identifier) { 'test-group' }
  let(:member) { instance_double(Memberships::Member, kind: 'user', id: 'test-user') }
  let(:group_resource) { instance_double(Resource, id: 'test-account:group:test-group', resource_id: 'test-account:group:test-group', policy_id: 'policy-id') }
  let(:member_resource) { instance_double(Resource, id: 'test-account:user:test-user', resource_id: 'test-account:user:test-user') }
  let(:membership_record) { instance_double(RoleMembership, save: true, destroy: true) }

  describe '#add_member' do
    before do
      allow(res_service).to receive(:read_res).with(current_user, account, 'group', group_identifier).and_return(group_resource)
      allow(res_service).to receive(:read_res).with(current_user, account, 'user', 'test-user').and_return(member_resource)
      allow(role_membership_repo).to receive(:where).and_return(double(first: nil))
      allow(role_membership_repo).to receive(:create).and_return(membership_record)
      allow(Memberships::Member).to receive(:from_model).and_return(member)
    end

    it 'creates and saves a membership' do
      result = service.add_member(current_user, account, group_identifier, member)

      expect(role_membership_repo).to have_received(:create).with(
        role_id: group_resource.resource_id,
        member_id: member_resource.resource_id,
        admin_option: false,
        ownership: false,
        policy_id: group_resource.policy_id
      )
      expect(membership_record).to have_received(:save)
      expect(result).to eq(member)
    end
  end

  describe '#remove_member' do
    before do
      allow(res_service).to receive(:read_res).with(current_user, account, 'group', group_identifier).and_return(group_resource)
      allow(res_service).to receive(:read_res).with(current_user, account, 'user', 'test-user').and_return(member_resource)
      allow(Memberships::Member).to receive(:from_model).and_return(member)
    end

    it 'removes the membership' do
      allow(role_membership_repo).to receive(:where).and_return(double(first: membership_record))

      result = service.remove_member(current_user, account, group_identifier, member)

      expect(membership_record).to have_received(:destroy)
      expect(result).to eq(member)
    end

    it 'raises error if membership does not exist' do
      allow(role_membership_repo).to receive(:where).and_return(double(first: nil))

      expect do
        service.remove_member(current_user, account, group_identifier, member)
      end.to raise_error(Errors::Group::ResourceNotMember)
    end
  end
end
