# frozen_string_literal: true

require 'spec_helper'
include AnnotationsHandler

describe "Annotation Handler's value_by_name" do
  let(:name) { 'annotation_name' }
  let(:no_such_annotation) { 'no_such_annotation_name' }
  let(:value) { 'annotation_value' }
  let(:annotation) do
    double('annotation', name: 'annotation_name', value: 'annotation_value')
  end
  let(:secret) do
    double('secret', annotations: [annotation], 'id' => 'secret_id')
  end
  context 'when trying to get annotation by name' do
    it 'should return the annotation value when the annoation exists' do
      annotation_value = annotation_value_by_name(secret, name)
      expect(annotation_value).to eq(value)
    end
    it 'should raise an exception when the annotation does not exist' do
      expect(annotation_value_by_name(secret, :no_such_annotation)).to be_nil
    end
  end
end

describe "Annotation Handler's get_annotations" do
  let(:annotation) do
    double('annotation', name: 'annotation_name', value: 'annotation_value')
  end
  context 'when trying to filter secret with annotations' do
    let(:secret) do
      double('secret_name', annotations: [annotation], 'id' => 'annotation_secret_id')
    end

    it 'should return the empty array when annotation exists' do
      filtered_annotations = get_annotations(secret, ['annotation_name'])
      expect(filtered_annotations).to eq([])
    end
    it 'should return the array when the annotation does not exist' do
      expected_result = [{ name: 'annotation_name', value: 'annotation_value' }]
      filtered_annotations = get_annotations(secret, ['wrong_annotation_name'])
      expect(filtered_annotations).to eq(expected_result)
    end
    it 'should return the array when the filter is empty' do
      expected_result = [{ name: 'annotation_name', value: 'annotation_value' }]
      filtered_annotations = get_annotations(secret, [])
      expect(filtered_annotations).to eq(expected_result)
    end
  end
  context 'when trying to filter secret without annotations' do
    let(:secret_without_annotation) do
      double('no_annotation_secret_name', annotations: [], 'id' => 'no_annotion_secret_id')
    end
    it 'should return an empty array' do
      filtered_annotations = get_annotations(secret_without_annotation, ['annotation_name'])
      expect(filtered_annotations).to eq([])
    end
  end
end
