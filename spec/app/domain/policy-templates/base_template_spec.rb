# frozen_string_literal: true
require 'spec_helper'

describe PolicyTemplates::BaseTemplate do
  context "check throw error when called template" do
    it "raises an error" do
      expect { PolicyTemplates::BaseTemplate.new().template }
        .to raise_error(NotImplementedError)
    end
  end
end