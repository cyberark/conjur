# spec/domain/annotation/annotation_spec.rb
require 'spec_helper'

RSpec.describe(Annotations::Annotations) do
  describe '.from_input' do
    context 'with valid input' do
      let(:input) { { 'foo' => 'bar', 'baz' => 'qux' } }

      it 'returns a valid Annotations object' do
        annotations = described_class.from_input(input)
        expect(annotations).to be_a(described_class)
        expect(annotations['foo']).to eq('bar')
        expect(annotations['baz']).to eq('qux')
      end
    end

    context 'with invalid key' do
      let(:input) { { '<bad>' => 'value' } }

      it 'raises DomainValidationError' do
        expect { described_class.from_input(input) }.to raise_error(Validation::DomainValidationError)
      end
    end

    context 'with invalid value' do
      let(:input) { { 'goodkey' => '' } }

      it 'raises DomainValidationError' do
        expect { described_class.from_input(input) }.to raise_error(Validation::DomainValidationError)
      end
    end

    context 'with non-string value' do
      let(:input) { { 'foo' => 123 } }

      it 'raises DomainValidationError' do
        expect { described_class.from_input(input) }.to raise_error(Validation::DomainValidationError)
      end
    end
  end

  describe '.from_model' do
    let(:model) do
      [
        double('Annotation', name: 'a', value: '1'),
        double('Annotation', name: 'b', value: '2')
      ]
    end

    it 'returns a hash of name => value' do
      result = described_class.from_model(model)
      expect(result).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'returns empty hash for empty model' do
      expect(described_class.from_model([])).to eq({})
    end
  end
end
