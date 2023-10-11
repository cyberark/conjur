# frozen_string_literal: true

require 'spec_helper'

describe Authentication::OptionalApiKey do

  context "annotation check" do

    subject do
      Class.new { include Authentication::OptionalApiKey }.new
    end

    it { subject.annotation_true?(Annotation.new(name: 'authn/api-key', value: 'true')).should be_truthy }

    it { subject.annotation_true?(Annotation.new(name: 'authn/api-key', value: 'false')).should be_falsey }

    it { subject.annotation_true?(Annotation.new(name: 'authn/other-key', value: 'true')).should be_falsey }
  end
end

