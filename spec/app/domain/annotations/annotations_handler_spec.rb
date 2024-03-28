# frozen_string_literal: true

require 'spec_helper'
include AnnotationsHandler

describe "Annotation Handler's get_annotations" do
  let(:annotation) do
    double('annotation', name: 'annotation_name', value: 'annotation_value')
  end
  context 'get annotations when there are annotations' do
    let(:secret) do
      double('secret_name', annotations: [annotation], 'id' => 'annotation_secret_id')
    end
    it 'should return the secret annotations as is when the filter is empty' do
      expected_result = [{ name: 'annotation_name', value: 'annotation_value' }]
      expect(get_annotations(secret)).to eq(expected_result)
    end
  end
  context 'get annotations when there are no annotations' do
    let(:secret_without_annotation) do
      double('no_annotation_secret_name', annotations: [], 'id' => 'no_annotation_secret_id')
    end
    it 'should return an empty array' do
      expect(get_annotations(secret_without_annotation)).to eq([])
    end
  end
end
