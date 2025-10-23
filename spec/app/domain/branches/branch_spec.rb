# spec/domain/branch/branch_spec.rb
require 'spec_helper'

RSpec.describe(Branches::Branch, type: :model) do
  let(:valid_name) { 'test-branch' }
  let(:valid_branch) { 'data' }
  let(:valid_owner) { instance_double(Branches::Owner, kind: 'user', id: 'alice', set?: true) }
  let(:valid_annotations) { { 'key1' => 'value1', 'key2' => 'value2' } }

  describe 'initialization' do
    it 'creates a valid branch with proper attributes' do
      branch = Branches::Branch.new(valid_name, valid_branch, valid_owner, valid_annotations)

      expect(branch.name).to eq(valid_name)
      expect(branch.branch).to eq(valid_branch)
      expect(branch.owner).to eq(valid_owner)
      expect(branch.annotations).to eq(valid_annotations)
    end

    it 'raises DomainValidationError when name is invalid' do
      expect { Branches::Branch.new('', valid_branch, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)
    end

    it 'raises DomainValidationError when branch is invalid' do
      expect { Branches::Branch.new(valid_name, '', valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)
    end

    it 'raises DomainValidationError when name contains invalid characters' do
      expect { Branches::Branch.new('test<branch>', valid_branch, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)
    end

    it 'raises DomainValidationError when branch contains invalid characters' do
      expect { Branches::Branch.new(valid_name, 'invalid<branch>', valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)
    end

    it 'raises DomainValidationError when branch depth is to big' do
      depth_branch = "data/#{'sub/' * Validation::IDENTIFIER_MAX_DEPTH}branch"
      expect { Branches::Branch.new(valid_name, depth_branch, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)

      depth_branch = "/data/#{'sub/' * Validation::IDENTIFIER_MAX_DEPTH}branch"
      expect { Branches::Branch.new(valid_name, depth_branch, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)

      depth_branch = "data/#{'sub/' * Validation::IDENTIFIER_MAX_DEPTH}branch"
      expect { Branches::Branch.new(valid_name, depth_branch, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)

      depth_branch = "/data/#{'sub/' * Validation::IDENTIFIER_MAX_DEPTH}branch/"
      expect { Branches::Branch.new(valid_name, depth_branch, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)
    end

    it 'raises DomainValidationError when full ID exceeds maximum length' do
      # / will be added so total length will exceed the limit by 1
      long_branch = 'a' * (Validation::IDENTIFIER_MAX_LENGTH - valid_name.length)
      expect { Branches::Branch.new(valid_name, long_branch, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)
    end

    it 'raises DomainValidationError when nil is a name' do
      expect { Branches::Branch.new(nil, valid_branch, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)

      expect { Branches::Branch.new(valid_name, nil, valid_owner, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)

      expect { Branches::Branch.new(valid_name, valid_branch, nil, valid_annotations) }
        .to raise_error(Validation::DomainValidationError)

      expect { Branches::Branch.new(valid_name, valid_branch, valid_owner, nil) }
        .to raise_error(Validation::DomainValidationError)
    end
  end

  describe '.from_input' do
    let(:valid_input) do
      {
        name: valid_name,
        branch: valid_branch,
        owner: { kind: 'user', id: 'alice' },
        annotations: valid_annotations
      }
    end

    it 'creates a branch from input hash' do
      allow(Branches::Owner).to receive(:from_input).and_return(valid_owner)
      allow(Annotations::Annotations).to receive(:from_input).and_return(valid_annotations)

      branch = Branches::Branch.from_input(valid_input)

      expect(branch.name).to eq(valid_name)
      expect(branch.branch).to eq(valid_branch)
      expect(branch.owner).to eq(valid_owner)
      expect(branch.annotations).to eq(valid_annotations)
    end

    it 'creates a branch with default owner when owner is empty' do
      input_without_owner = valid_input.except(:owner)
      allow(Branches::Owner).to receive(:new).and_return(valid_owner)
      allow(Annotations::Annotations).to receive(:from_input).and_return(valid_annotations)

      branch = Branches::Branch.from_input(input_without_owner)

      expect(branch.owner).to eq(valid_owner)
    end

    it 'creates a branch with empty annotations when annotations are empty' do
      input_without_annotations = valid_input.except(:annotations)
      allow(Branches::Owner).to receive(:from_input).and_return(valid_owner)
      allow(Annotations::Annotations).to receive(:from_input).and_return({})

      branch = Branches::Branch.from_input(input_without_annotations)

      expect(branch.annotations).to eq({})
    end
  end

  describe '.from_model' do
    let(:model) do
      instance_double('Model',
                      identifier: 'data/test-branch',
                      owner_id: 'user:account:user:alice',
                      annotations: [double('Annotation')])
    end

    it 'creates a branch from model' do
      allow(Branches::Branch).to receive(:res_name).with('data/test-branch').and_return('test-branch')
      allow(Branches::Branch).to receive(:domain_id).with('data').and_return('data')
      allow(Branches::Branch).to receive(:parent_identifier).with('data/test-branch').and_return('data')
      allow(Branches::Owner).to receive(:from_model_id).and_return(valid_owner)
      allow(Annotations::Annotations).to receive(:from_model).and_return(valid_annotations)

      branch = Branches::Branch.from_model(model)

      expect(branch.name).to eq('test-branch')
      expect(branch.branch).to eq('data')
      expect(branch.owner).to eq(valid_owner)
      expect(branch.annotations).to eq(valid_annotations)
    end
  end

  describe '#identifier' do
    it 'returns correct identifier for non-root branch' do
      branch = Branches::Branch.new(valid_name, valid_branch, valid_owner, valid_annotations)
      allow(branch).to receive(:to_identifier).with(valid_branch, valid_name).and_return('data/test-branch')

      expect(branch.identifier).to eq('data/test-branch')
    end

    it 'returns correct identifier for root branch' do
      branch = Branches::Branch.new(valid_name, '/', valid_owner, valid_annotations)
      allow(branch).to receive(:to_identifier).with('/', valid_name).and_return('test-branch')

      expect(branch.identifier).to eq('test-branch')
    end
  end

  describe '#to_s' do
    it 'returns proper string representation' do
      branch = Branches::Branch.new(valid_name, valid_branch, valid_owner, valid_annotations)
      expected_string = "#<Branch name=test-branch branch=data owner=#{valid_owner} annotations=#{valid_annotations}>"

      expect(branch.to_s).to eq(expected_string)
    end
  end

  describe '#as_json' do
    it 'excludes validation_context and errors from json representation' do
      branch = Branches::Branch.new(valid_name, valid_branch, valid_owner, valid_annotations)
      json = branch.as_json

      expect(json).not_to include('validation_context')
      expect(json).not_to include('errors')
    end
  end
end
