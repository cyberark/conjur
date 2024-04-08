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

describe "Annotation Handler's validate annotations" do
  context 'annotation without a name' do
    let(:annotations) do
      [{ :value=> 'annotation value'},
       { :name=> 'valid_annotation', :value=> 'valid annotation value'}]
    end
    it 'input validation will fail' do
      expect { validate_annotations(annotations)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context 'annotation without a value' do
    let(:annotations) do
      [{ :name=> 'annotation_name'}]
    end
    it 'input validation will fail' do
      expect { validate_annotations(annotations)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context 'annotation name not valid' do
    let(:annotations) do
      [{ :name=> 'annotation name', :value=> 'annotation value'}]
    end
    it 'input validation will fail' do
      expect { validate_annotations(annotations)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context 'annotation name type not valid' do
    let(:annotations) do
      [{ :name=> 5, :value=> 'annotation value'}]
    end
    it 'input validation will fail' do
      expect { validate_annotations(annotations)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context 'annotation value type not valid' do
    let(:annotations) do
      [{ :name=> "annotation_name", :value=> 5}]
    end
    it 'input validation will fail' do
      expect { validate_annotations(annotations)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context 'annotation valid' do
    let(:annotations) do
      [{ :name=> "anno4t/atTion_na-me", :value=> "value"}]
    end
    it 'input validation passes' do
      expect { validate_annotations(annotations)
      }.to_not raise_error
    end
  end
end
