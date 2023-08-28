# frozen_string_literal: true
require 'spec_helper'

describe "IssuerTypeFactory input validation" do

  context "when issuer type is supported" do
    it "then relevant issuer type is being created" do
      expect { IssuerTypeFactory.new.create_issuer_type("aws") }
        .to_not raise_error
    end
  end

  context "when issuer type is supported but with upper case" do
    it "then relevant issuer type is being created" do
      expect { IssuerTypeFactory.new.create_issuer_type("AWS") }
        .to_not raise_error
    end
  end

  context "when issuer type is not supported" do
    it "then the factory returns an error" do
      expect { IssuerTypeFactory.new.create_issuer_type("abc") }
        .to raise_error(ApplicationController::BadRequest)
    end
  end
end
