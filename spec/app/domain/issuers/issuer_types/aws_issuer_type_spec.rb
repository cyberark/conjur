# frozen_string_literal: true
require 'spec_helper'

describe "AwsIssuerType input validation" do
  context "when all input is valid" do
    it "then the input validation succeeds" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000,
                                                type: "aws",
                                                data: {
                                                  access_key_id: "a", 
                                                  secret_access_key: "a"
                                                })
      expect { AwsIssuerType.new.validate(params) }
        .to_not raise_error
    end
  end

  context "when key id is not given in the data field" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  secret_access_key: "a" 
                                                })
      expect { AwsIssuerType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when secret access key is not given in the data field" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: "a" 
                                                })
      expect { AwsIssuerType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when key id is not a string" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: 1, 
                                                  secret_access_key: "a" 
                                                })
      expect { AwsIssuerType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when key id is an empty string" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: "", 
                                                  secret_access_key: "a" 
                                                })
      expect { AwsIssuerType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when secret access key is not a string" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: "a", 
                                                  secret_access_key: 1 
                                                })
      expect { AwsIssuerType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when secret access key is an empty string" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000, 
                                                type: "aws", 
                                                data: { 
                                                  access_key_id: "a", 
                                                  secret_access_key: "" 
                                                })
      expect { AwsIssuerType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end

  context "when invalid parameter is added to the data" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(id: "aws-issuer-1",
                                                max_ttl: 2000,
                                                type: "aws",
                                                data: {
                                                  access_key_id: "a",
                                                  secret_access_key: "",
                                                  invalid_param: "a"
                                                })
      expect { AwsIssuerType.new.validate(params) }
        .to raise_error(ApplicationController::BadRequest)
    end
  end
end
