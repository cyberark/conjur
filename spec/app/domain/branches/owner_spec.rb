# spec/domain/branch/owner_spec.rb
require 'spec_helper'

RSpec.describe(Branches::Owner) do
  describe '#initialize' do
    it 'has correct OWNER_KINDS' do
      expect(Branches::Owner::OWNER_KINDS).to include('user', 'host', 'group', 'policy')
    end

    it 'creates a valid owner with allowed kind and id' do
      owner = described_class.new('user', 'alice', is_set: true)
      expect(owner.kind).to eq('user')
      expect(owner.id).to eq('alice')
      expect(owner.set?).to be(true)
    end

    it 'raises error for invalid kind' do
      expect { described_class.new('invalid', 'alice', is_set: true) }
        .to raise_error(Validation::DomainValidationError, /is not a valid owner kind/)
    end

    it 'raises error for invalid id format' do
      expect { described_class.new('user', 'invalid id!', is_set: true) }
        .to raise_error(Validation::DomainValidationError, /Wrong path/)
    end

    it 'does not raise error if not set' do
      expect { described_class.new('user', 'alice', is_set: false) }
        .not_to raise_error
    end

    it 'raises error for invalid nil id' do
      expect { described_class.new('user', nil, is_set: true) }
        .to raise_error(Validation::DomainValidationError, /can't be blank/)
    end

    it 'raises error for empty id' do
      expect { described_class.new('user', '', is_set: true) }
        .to raise_error(Validation::DomainValidationError, /can't be blank/)
    end

    it 'raises error for nil kind' do
      expect { described_class.new(nil, 'alice', is_set: true) }
        .to raise_error(Validation::DomainValidationError, /can't be blank/)
    end

    it 'raises error for too long kind' do
      long_kind = 'a' * (Validation::PATH_LENGTH_MAX + 1)
      expect { described_class.new(long_kind, 'alice', is_set: true) }
        .to raise_error(Validation::DomainValidationError,  "Kind '#{long_kind}' is not a valid owner kind")
    end
  end

  describe '.from_input' do
    it 'creates a valid owner from input hash' do
      input = { kind: 'host', id: 'host1' }
      owner = described_class.from_input(input)
      expect(owner.kind).to eq('host')
      expect(owner.id).to eq('host1')
      expect(owner.set?).to be(true)
    end
  end

  describe '.from_model_id' do
    it 'creates a valid owner from model id' do
      # Use a valid kind, e.g., 'user'
      model_id = 'rspec:user:alice'
      owner = Branches::Owner.from_model_id(model_id)
      expect(owner.kind).to eq('user')
      expect(owner.id).to eq('alice')
      expect(owner).to be_a(Branches::Owner)
    end
  end

  describe '#not_admin?' do
    it 'returns false for user admin' do
      owner = described_class.new('user', 'admin', is_set: true)
      expect(owner.not_admin?).to be(false)
    end

    it 'returns true for non-admin user' do
      owner = described_class.new('user', 'bob', is_set: true)
      expect(owner.not_admin?).to be(true)
    end

    it 'returns true for non-user kind' do
      owner = described_class.new('group', 'admin', is_set: true)
      expect(owner.not_admin?).to be(true)
    end
  end

  describe '#as_json' do
    it 'returns a hash without validation fields' do
      owner = described_class.new('user', 'alice', is_set: true)
      json = owner.as_json
      expect(json).to include('kind' => 'user', 'id' => 'alice')
      expect(json).not_to have_key('validation_context')
      expect(json).not_to have_key('errors')
      expect(json).not_to have_key('is_set')
    end
  end

  describe '#to_s' do
    it 'returns a string representation' do
      owner = described_class.new('user', 'alice', is_set: true)
      expect(owner.to_s).to include('kind=user', 'id=alice', 'set=true')
    end
  end
end
