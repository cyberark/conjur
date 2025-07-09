# spec/domain/branch/branch_up_part_spec.rb
require 'spec_helper'

RSpec.describe(Domain::BranchUpPart) do
  let(:owner) { instance_double(Domain::Owner) }
  let(:annotations) { { 'key1' => 'value1' } }

  describe '#initialize' do
    it 'sets owner and annotations' do
      part = described_class.new(owner, annotations)
      expect(part.owner).to eq(owner)
      expect(part.annotations).to eq(annotations)
    end

    it 'raises on invalid input' do
      allow_any_instance_of(described_class).to receive(:invalid?).and_return(true)
      expect { described_class.new(owner, annotations) }.to raise_error(Domain::Validation::DomainValidationError)
    end
  end

  describe '.from_input' do
    let(:owner_input) { { kind: 'user', id: 'alice' } }
    let(:annotations_input) { { 'foo' => 'bar' } }

    it 'builds from input with owner and annotations' do
      owner_obj = instance_double(Domain::Owner)
      annotations_obj = { 'foo' => 'bar' }
      allow(Domain::Owner).to receive(:from_input).with(owner_input).and_return(owner_obj)
      allow(Domain::Annotations).to receive(:from_input).with(annotations_input).and_return(annotations_obj)

      part = described_class.from_input(owner: owner_input, annotations: annotations_input)
      expect(part.owner).to eq(owner_obj)
      expect(part.annotations).to eq(annotations_obj)
    end

    it 'defaults owner and annotations if not provided' do
      owner_obj = instance_double(Domain::Owner)
      annotations_obj = {}
      allow(Domain::Owner).to receive(:new).and_return(owner_obj)
      allow(Domain::Annotations).to receive(:from_input).with({}).and_return(annotations_obj)

      part = described_class.from_input({})
      expect(part.owner).to eq(owner_obj)
      expect(part.annotations).to eq(annotations_obj)
    end
  end
end
