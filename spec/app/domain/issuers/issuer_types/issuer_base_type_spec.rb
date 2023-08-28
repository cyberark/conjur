# frozen_string_literal: true
require 'spec_helper'

class BaseTypeTest < IssuerBaseType
  def validate(params)
    super
  end
end

describe "IssuerBaseType input validation" do
  
  context "when all base input is valid" do
    it "then the input validation succeeds" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000, 
                                                type: "aws",
                                                data: {})
      expect { BaseTypeTest.new.validate(params) }
        .to_not raise_error
    end
  end

  context "when max_ttl is a negative number" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: -2000, 
                                                type: "aws",
                                                data: {})
      expect { BaseTypeTest.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when max_ttl is 0" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 0, 
                                                type: "aws",
                                                data: {})
      expect { BaseTypeTest.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when max_ttl is a floating number" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 4.5, 
                                                type: "aws",
                                                data: {})
      expect { BaseTypeTest.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when id is a number" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: 1, 
                                                max_ttl: 2000, 
                                                type: "aws",
                                                data: {})
      expect { BaseTypeTest.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when id is longer than 60 characters" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "a" * 61,
                                                max_ttl: 2000,
                                                type: "aws",
                                                data: {})
      expect { BaseTypeTest.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when id has invalid character ^" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "a^", 
                                                max_ttl: 2000, 
                                                type: "aws",
                                                data: {})
      expect { BaseTypeTest.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when id has invalid character of a space" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "a hf", 
                                                max_ttl: 2000, 
                                                type: "aws",
                                                data: {})
      expect { BaseTypeTest.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when invalid parameter is added to the body main section" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000,
                                                type: "aws",
                                                invalid_param: "a",
                                                data: {})
      expect { AwsIssuerType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end
end
