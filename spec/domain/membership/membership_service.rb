# spec/domain/membership/membership_service_spec.rb
require 'spec_helper'

RSpec.describe Domain::MembershipService, type: :service do
  let(:membership_repo) { class_double("Membership") }
  let(:logger) { instance_double(Logger, debug?: false, info: nil) }
  let(:service) { described_class.instance }

  before do
    service.instance_variable_set(:@membership_repo, membership_repo)
    service.instance_variable_set(:@logger, logger)
  end

  describe '#add_member' do
    it 'creates and saves a membership' do
      membership = instance_double("Membership", save: true)
      allow(membership_repo).to receive(:create).and_return(membership)

      service.add_member('group_id', 'user_id')

      expect(membership_repo).to have_received(:create).with(
        group_id: 'group_id',
        user_id: 'user_id'
      )
      expect(membership).to have_received(:save)
    end
  end

  describe '#read_member' do
    let(:membership) { instance_double("Membership", visible_to?: true) }

    it 'returns the membership if visible' do
      allow(service).to receive(:fetch_member).and_return(membership)

      result = service.read_member('role', 'group_id', 'user_id')

      expect(result).to eq(membership)
    end

    it 'raises RecordNotFound if not visible' do
      allow(service).to receive(:fetch_member).and_return(membership)
      allow(membership).to receive(:visible_to?).and_return(false)

      expect {
        service.read_member('role', 'group_id', 'user_id')
      }.to raise_error(Exceptions::RecordNotFound)
    end
  end

  describe '#remove_member' do
    it 'removes the membership' do
      membership = instance_double("Membership", destroy: true)
      allow(service).to receive(:fetch_member).and_return(membership)

      result = service.remove_member('group_id', 'user_id')

      expect(membership).to have_received(:destroy)
      expect(result).to eq(true)
    end

    it 'raises RecordNotFound if membership does not exist' do
      allow(service).to receive(:fetch_member).and_return(nil)

      expect {
        service.remove_member('group_id', 'user_id')
      }.to raise_error(Exceptions::RecordNotFound)
    end
  end
end
