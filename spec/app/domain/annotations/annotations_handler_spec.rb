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
      expect{annotation_value_by_name(secret, :no_such_annotation)}.to raise_error(Errors::Conjur::AnnotationNotFound)
    end
  end
end
