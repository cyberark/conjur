# spec/domain/annotation/annotation_validator_spec.rb
require 'spec_helper'

RSpec.describe(Annotations::Validations::AnnotationsValidator) do
  let(:validator) { described_class.new }
  let(:annotations_class) do
    Class.new(Hash) do
      include ActiveModel::Validations
      validates_with Annotations::Validations::AnnotationsValidator
    end
  end

  def build_annotations(hash)
    obj = annotations_class.new.merge(hash)
    obj.valid?
    obj
  end

  context 'with valid annotations' do
    it 'does not add errors' do
      annotations = build_annotations('key1' => 'value1', 'key2' => 'value2')
      expect(annotations.errors).to be_empty
    end
  end

  context 'with invalid annotation key' do
    it 'adds error for invalid format' do
      annotations = build_annotations('bad<key>' => 'value')
      expect(annotations.errors[:'bad<key>']).to include(/format error/)
    end

    it 'adds error for too short key' do
      annotations = build_annotations('' => 'value')
      expect(annotations.errors[:'']).to include(/length cannot exceeded 1/)
    end

    it 'adds error for too long key' do
      long_key = 'k' * 121
      annotations = build_annotations(long_key => 'value')
      expect(annotations.errors[long_key.to_sym]).to include(/length cannot exceeded 120/)
    end
  end

  context 'with invalid annotation value' do
    it 'adds error for non-string value' do
      annotations = build_annotations('key' => 123)
      expect(annotations.errors[:key]).to include(/should have string value/)
    end

    it 'adds error for invalid format' do
      annotations = build_annotations('key' => "bad'value")
      expect(annotations.errors[:key]).to include(/format error/)
    end

    it 'adds error for too short value' do
      annotations = build_annotations('key' => '')
      expect(annotations.errors[:key]).to include(/length cannot exceeded 1/)
    end

    it 'adds error for too long value' do
      long_value = 'v' * 121
      annotations = build_annotations('key' => long_value)
      expect(annotations.errors[:key]).to include(/length cannot exceeded 120/)
    end
  end
end
