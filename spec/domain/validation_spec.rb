# spec/domain/validation_spec.rb
require 'spec_helper'

RSpec.describe(Domain::Validation) do
  include described_class

  describe 'validate_identifier' do
    it 'validates a correct identifier' do
      expect { validate_identifier('valid-identifier') }
        .not_to raise_error
    end

    it 'raises error for too long identifier' do
      long_identifier = 'a' * (Domain::Validation::IDENTIFIER_MAX_LENGTH + 1)
      expect { validate_identifier(long_identifier) }
        .to raise_error(Domain::Validation::DomainValidationError, Domain::Validation::IDENTIFIER_MAX_LENGTH_MSG)
    end

    it 'raises error for a identifier with too many nestings' do
      deep_identifier = "#{'a/' * (Domain::Validation::IDENTIFIER_MAX_DEPTH + 1)}b"
      expect { validate_identifier(deep_identifier) }
        .to raise_error(Domain::Validation::DomainValidationError, Domain::Validation::IDENTIFIER_MAX_DEPTH_MSG)
    end
  end

  describe 'constants' do
    it 'has correct NAME_LENGTH_MIN' do
      expect(Domain::Validation::NAME_LENGTH_MIN).to eq(1)
    end

    it 'has correct NAME_LENGTH_MAX' do
      expect(Domain::Validation::NAME_LENGTH_MAX).to eq(60)
    end

    it 'has correct NAME_PATTERN' do
      expect('Valid-Name_123').to match(Domain::Validation::NAME_PATTERN)
      expect('Invalid Name!').not_to match(Domain::Validation::NAME_PATTERN)
    end

    it 'has correct PATH_PATTERN' do
      expect('valid/path_123').to match(Domain::Validation::PATH_PATTERN)
      expect('invalid path!').not_to match(Domain::Validation::PATH_PATTERN)
    end

    it 'has correct OWNER_KINDS' do
      expect(Domain::Validation::OWNER_KINDS).to include('user', 'host', 'group', 'policy')
    end
  end

  describe Domain::Validation::DomainValidationError do
    it 'is a RuntimeError' do
      expect(Domain::Validation::DomainValidationError).to be < RuntimeError
    end

    it 'can be raised and rescued' do
      expect { raise Domain::Validation::DomainValidationError, 'error' }.to raise_error(Domain::Validation::DomainValidationError, 'error')
    end
  end
end
