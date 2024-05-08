require 'spec_helper'

describe ParamsValidator do
  class Controller
    include ParamsValidator
  end

  subject(:controller) { Controller.new }

  describe "Different validators" do
    context "validate privilege" do
      it "not valid privilege" do
        expect { controller.validate_privilege("resource", ["read", "create"], %w[read update execute])
        }.to raise_error(Errors::Conjur::ParameterValueInvalid, "CONJ00191W The value in the 'Resource resource privileges' parameter is not valid. Error: Allowed values are [read execute update]")
      end
      it " valid privilege" do
        expect { controller.validate_privilege("resource", ["read", "update"], %w[read update execute])
        }.to_not raise_error
      end
    end

    context "validate resource kind" do
      it "not valid kind" do
        expect { controller.validate_resource_kind("workload", "resource",  %w[host user group])
        }.to raise_error(Errors::Conjur::ParameterValueInvalid, "CONJ00191W The value in the 'Resource resource kind' parameter is not valid. Error: Allowed values are [\"host\", \"user\", \"group\"]")
      end
      it " alid kind" do
        expect { controller.validate_resource_kind("host", "resource",  %w[host user group])
        }.to_not raise_error
      end
    end

    context "validate field type" do
      it "not valid field type" do
        expect { controller.validate_field_type("ttl",{type: Numeric,value: "120"})}.
          to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'ttl' parameter must be of 'type=Numeric'")
      end
      it "valid field type" do
        expect { controller.validate_field_type("ttl",{type: Numeric,value: 120})
        }.to_not raise_error
      end
    end

    context "validate field required" do
      it "field value is nil" do
        expect { controller.validate_field_required("name",{type: String,value: nil})}.
          to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: name")
      end
      it "field value is empty" do
        expect { controller.validate_field_required("name",{type: String,value: ""})}.
          to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: name")
      end
      it "valid field value" do
        expect { controller.validate_field_required("name",{type: String,value: "hello"})
        }.to_not raise_error
      end
    end

    context "validate region" do
      it "not valid region regex" do
        expect { controller.validate_region("region",{type: String,value: "us-east"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "not valid region length" do
        expect { controller.validate_region("region",{type: String,value: "#{create_string(30,'u')}s-east-1"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "valid region" do
        expect { controller.validate_region("region",{type: String,value: "us-east-2"})
        }.to_not raise_error
      end
    end

    context "validate role arn" do
      it "not valid role arn regex" do
        expect { controller.validate_role_arn("role_arn",{type: String,value: "aws:iam::123456789012:role/my-role-name"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "not valid role arn length" do
        expect { controller.validate_role_arn("region",{type: String,value: "arn:aws:iam::123456789012:role/my-role-nam#{create_string(1000,'e')}"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "valid role arn" do
        expect { controller.validate_role_arn("region",{type: String,value: "arn:aws:iam::123456789012:role/my-role-name"})
        }.to_not raise_error
      end
    end

    context "validate mime type" do
      it "not valid mime type regex" do
        expect { controller.validate_mime_type("mime_type",{type: String,value: "plain+text"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "not valid mime type length" do
        expect { controller.validate_mime_type("mime_type",{type: String,value: "plain/tex#{create_string(98,'t')}"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "valid mime type" do
        expect { controller.validate_mime_type("mime_type",{type: String,value: "plain/text"})
        }.to_not raise_error
      end
    end

    context "validate path" do
      it "not valid path regex" do
        expect { controller.validate_path("path",{type: String,value: "data+dynamic"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "not valid path length" do
        expect { controller.validate_path("path",{type: String,value: "data/dynami#{create_string(495,'t')}"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "valid path" do
        expect { controller.validate_path("path",{type: String,value: "data/dynamic"})
        }.to_not raise_error
      end
    end

    context "validate id" do
      it "not valid id regex" do
        expect { controller.validate_id("id",{type: String,value: "seceret/name"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "not valid id length" do
        expect { controller.validate_id("id",{type: String,value: "nam#{create_string(59,'e')}"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "valid id" do
        expect { controller.validate_id("id",{type: String,value: "s4c-ret_na.Me"})
        }.to_not raise_error
      end
    end

    context "validate resource id" do
      it "not valid resource id regex" do
        expect { controller.validate_resource_id("id",{type: String,value: "luba_tsirulnik@cyberark.cloud.176321!"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "not valid id length" do
        expect { controller.validate_resource_id("id",{type: String,value: "nam#{create_string(599,'e')}"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "valid id" do
        expect { controller.validate_resource_id("id",{type: String,value: "luba_tsirulnik@cyberark.cloud.176321"})
        }.to_not raise_error
      end
    end

    context "validate annotation value" do
      it "not valid annotation value regex" do
        expect { controller.validate_annotation_value("id",{type: String,value: "seceret<name"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "not valid annotation value length" do
        expect { controller.validate_annotation_value("id",{type: String,value: "nam#{create_string(118,'e')}"})
        }.to raise_error(ApplicationController::UnprocessableEntity)
      end
      it "valid annotation value" do
        expect { controller.validate_annotation_value("id",{type: String,value: "s4c-ret_na%$*&+{#Me"})
        }.to_not raise_error
      end
    end
  end

  def create_string(length, char = 'a')
    char * length
  end
end