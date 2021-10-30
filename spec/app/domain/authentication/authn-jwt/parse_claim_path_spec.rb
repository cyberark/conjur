# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::ParseClaimPath) do

  invalid_examples = {
    "When claim value is nil":                                        [nil],
    "When claim is empty string":                                     [""],
    "When one of claim names starts with digit":                      ["kuku/9agfdsg"],
    "When one of claim names starts with dot '.'":                    [".claim1/claim2"],
    "When claim name is 1 dot character '.'":                         ["."],
    "When claim name is 1 dot character '*'":                         ["*"],
    "When claim name starts with forbidden character '['":            ["kuku[12]/$agfdsg"],
    "When claim name ends with forbidden character '#'":              ["$agfdsg#"],
    "When claim name contains forbidden character in the middle '!'": ["claim/a!c/wd"],
    "When claim name starts with spaces":                             ["claim1/  claim2/claim3"],
    "When claim name ends with spaces":                               ["claim1  /claim2/claim3"],
    "When claim name contains with spaces":                           ["claim1/claim2/clai  m3"],
    "When claim path starts from '/'":                                ["/claim"],
    "When claim path ends with '/'":                                  ["dflk/claim/"]
  }

  valid_examples = {
    "Single claim name":
      ["claim",
       %w[claim]],
    "Multiple single character claims":
      ["F/f/_/$",
       %w[F f _ $]],
    "Multiple claims with indexes":
      ["claim1/cla245im/c.l.a.i.m.3/claim4.",
       %w[claim1 cla245im c.l.a.i.m.3 claim4.]]
  }

  context "Invalid claim path" do
    invalid_examples.each do |description, (input)|
      context "#{description}" do
        it "raises an error" do
          expect { ::Authentication::AuthnJwt::ParseClaimPath.new.(claim: input) }
            .to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
        end
      end
    end
  end

  context "Valid claim path" do
    valid_examples.each do |description, (input, output)|
      context "#{description}" do
        it "works" do
          expect(Authentication::AuthnJwt::ParseClaimPath.new.(claim: input))
            .to eql(output)
        end
      end
    end
  end
end
