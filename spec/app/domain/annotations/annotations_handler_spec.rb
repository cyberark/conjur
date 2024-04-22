# frozen_string_literal: true

require 'spec_helper'
include AnnotationsHandler

describe "Annotation Handler get annotations" do
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

describe "Annotation Handler validate annotations" do
  let(:annotations_handler) do
    my_instance = Object.new
    my_instance.extend(AnnotationsHandler)
    my_instance
  end
  let(:annotations) do
    [{ :name=> "description", :value=> "desc"}]
  end

  context "when validating annotations" do
    it "correct validators are being called for each field" do
      expect(annotations_handler).to receive(:validate_field_required).with(:"annotation name",{type: String,value: "description"})
      expect(annotations_handler).to receive(:validate_field_required).with(:"annotation value",{type: String,value: "desc"})

      expect(annotations_handler).to receive(:validate_field_type).with(:"annotation name",{type: String,value: "description"})
      expect(annotations_handler).to receive(:validate_field_type).with(:"annotation value",{type: String,value: "desc"})

      expect(annotations_handler).to receive(:validate_path).with(:"annotation name",{type: String,value: "description"})

      expect(annotations_handler).to receive(:validate_annotation_value).with(:"annotation value",{type: String,value: "desc"})

      annotations_handler.validate_annotations(annotations)
    end
  end
end
