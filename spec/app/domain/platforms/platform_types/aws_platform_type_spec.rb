# frozen_string_literal: true
require 'spec_helper'

describe "AwsPlatformType input validation" do
  context "when all input is valid" do
    it "then the input validation succeeds" do
      params = ActionController::Parameters.new(id: "aws-platform-1",
                                                max_ttl: 2000,
                                                type: "aws",
                                                data: {
                                                  access_key_id: "a", 
                                                  access_key_secret: "a" 
                                                })
      
      expect { AwsPlatformType.new.validate(params) }
        .to_not raise_error
    end
  end

  context "when key id is not given in the data field" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-platform-1", 
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_secret: "a" 
                                                })
      expect { AwsPlatformType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when key secret is not given in the data field" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-platform-1", 
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: "a" 
                                                })
      expect { AwsPlatformType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when key id is not a string" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-platform-1", 
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: 1, 
                                                  access_key_secret: "a" 
                                                })
      expect { AwsPlatformType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when key id is an empty string" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-platform-1", 
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: "", 
                                                  access_key_secret: "a" 
                                                })
      expect { AwsPlatformType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when key secret is not a string" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-platform-1", 
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: "a", 
                                                  access_key_secret: 1 
                                                })
      expect { AwsPlatformType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when key secret is an empty string" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-platform-1", 
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: "a", 
                                                  access_key_secret: "" 
                                                })
      expect { AwsPlatformType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end
end
