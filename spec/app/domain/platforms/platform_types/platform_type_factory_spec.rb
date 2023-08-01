# frozen_string_literal: true
require 'spec_helper'

describe "PlatformTypeFactory input validation" do

  context "when platform type is supported" do
    it "then relevant platform type is being created" do
      expect { PlatformTypeFactory.new.create_platform_type("aws") }
        .to_not raise_error
    end
  end

  context "when platform type is supported but with upper case" do
    it "then relevant platform type is being created" do
      expect { PlatformTypeFactory.new.create_platform_type("AWS") }
        .to_not raise_error
    end
  end

  context "when platform type is not supported" do
    it "then the factory returns an error" do
      expect { PlatformTypeFactory.new.create_platform_type("abc") }
        .to raise_error(ApplicationController::BadRequest)
    end
  end
end
