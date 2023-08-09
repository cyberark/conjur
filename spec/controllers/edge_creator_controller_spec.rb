# frozen_string_literal: true
require 'spec_helper'

describe EdgeCreatorController, :type => :request do

  context "Edge name validation" do
    subject{ EdgeCreatorController.new }

    it "Edge names are validated" do
      expect { subject.send(:validate_name, "Edgy") }.to_not raise_error
      expect { subject.send(:validate_name, "Edgy_05") }.to_not raise_error

      expect { subject.send(:validate_name, nil) }.to raise_error
      expect { subject.send(:validate_name, "") }.to raise_error
      expect { subject.send(:validate_name, "Edgy!") }.to raise_error
      expect { subject.send(:validate_name, "SuperExtremelyLongEdgeName") }.to raise_error
    end
  end
end

