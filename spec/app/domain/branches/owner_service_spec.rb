# spec/domain/branch/owner_service_spec.rb
require 'spec_helper'

RSpec.describe(Branches::OwnerService) do
  let(:role_repository) { double('RoleRepository') }
  let(:logger) { instance_double(Logger, debug?: true, debug: nil) }
  let(:service) { described_class.send(:new, role_repository: role_repository, logger: logger) }

  describe '#resource_owner' do
    let(:parent_identifier) { 'data' }
    let(:owner) { Branches::Owner.new('user', 'alice', is_set: true) }

    it 'returns the given owner if already set' do
      result = service.resource_owner(parent_identifier, owner)
      expect(result.kind).to eq('user')
      expect(result.id).to eq('alice')
    end

    it 'returns a new Owner with kind user and id admin for root parent' do
      root_owner = Branches::Owner.new
      result = service.resource_owner('/', root_owner)
      expect(result.kind).to eq('user')
      expect(result.id).to eq('admin')
    end

    it 'returns a new Owner with kind policy and id as parent_identifier for non-root parent' do
      unset_owner = Branches::Owner.new
      result = service.resource_owner('data', unset_owner)
      expect(result.kind).to eq('policy')
      expect(result.id).to eq('data')
    end
  end

  describe '#check_owner_exists' do
    let(:account) { 'rspec' }
    let(:owner) { Branches::Owner.new('user', 'alice', is_set: true) }
    let(:role_id) { 'rspec:user:alice' }

    before do
      allow(service).to receive(:full_id).with(account, owner.kind, owner.id).and_return(role_id)
      allow(service).to receive(:res_identifier).with(owner.id).and_return(owner.id)
    end

    it 'returns owner if role exists' do
      allow(role_repository).to receive(:[]).with(role_id).and_return(double('Role'))
      expect(service.check_owner_exists(account, owner)).to eq(owner)
    end

    it 'raises RecordNotFound if role does not exist' do
      allow(role_repository).to receive(:[]).with(role_id).and_return(nil)
      expect { service.check_owner_exists(account, owner) }.to raise_error(Exceptions::RecordNotFound)
    end
  end
end
