# spec/domain/membership/member_spec.rb
require 'spec_helper'

RSpec.describe Memberships::Member do
  let(:valid_user_id) { '/users/123' }
  let(:valid_group_id) { '/groups/abc' }
  let(:invalid_id) { 'invalid</asdf' }

  describe '#initialize' do
    it 'creates a valid user member' do
      member = described_class.new('user', valid_user_id)
      expect(member.kind).to eq('user')
      expect(member.id).to eq(valid_user_id)
    end

    it 'has correct MEMBER_KINDS' do
      expect(Memberships::Member::MEMBER_KINDS).to include('host', 'user', 'group')
    end

    it 'raises error for invalid kind' do
      expect {
        described_class.new('invalid_kind', valid_user_id)
      }.to raise_error(Validation::DomainValidationError)
    end

    it 'raises error for invalid id format for user' do
      expect {
        described_class.new('user', invalid_id)
      }.to raise_error(Validation::DomainValidationError)
    end

    it 'raises error for invalid id format for group' do
      expect {
        described_class.new('group', invalid_id)
      }.to raise_error(Validation::DomainValidationError)
    end
  end

  describe '#to_s' do
    it 'returns string representation' do
      member = described_class.new('user', valid_user_id)
      expect(member.to_s).to eq("#<Member kind=user id=#{valid_user_id}>")
    end
  end

  describe '#as_json' do
    it 'returns json without validation_context and errors' do
      member = described_class.new('user', valid_user_id)
      json = member.as_json
      expect(json).not_to have_key('validation_context')
      expect(json).not_to have_key('errors')
    end
  end

  describe '.from_input' do
    it 'creates member from input hash' do
      input = { kind: 'user', id: valid_user_id }
      member = described_class.from_input(input)
      expect(member.kind).to eq('user')
      expect(member.id).to eq(valid_user_id)
    end
  end

  describe '.from_model' do
    it 'creates member from membership_db' do
      membership_db = double(member_id: '/groups/abc')
      allow(described_class).to receive(:kind).and_return('group')
      allow(described_class).to receive(:identifier).and_return(valid_group_id)
      member = described_class.from_model(membership_db)
      expect(member.kind).to eq('group')
      expect(member.id).to eq(valid_group_id)
    end
  end
end
