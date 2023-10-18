# frozen_string_literal: true

require 'spec_helper'

describe Authentication::OptionalApiKey do

  context "annotation check" do

    subject do
      Class.new { include Authentication::OptionalApiKey }.new
    end

    it { expect(subject.api_key_annotation_true?(Annotation.new(name: 'authn/api-key', value: 'true'))).to be_truthy }

    it { expect(subject.api_key_annotation_true?(Annotation.new(name: 'authn/api-key', value: 'false'))).to be_falsey }

    it { expect(subject.api_key_annotation_true?(Annotation.new(name: 'authn/other-key', value: 'true'))).to be_falsey }
  end
end

