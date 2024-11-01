# frozen_string_literal: true

require 'spec_helper'

# Test outline:
# - inject policy_result objs for the error and no-error cases
# - create the errors from EnhancedPolicyError class

describe Loader::Validate do
  @logger = Rails.logger

  mode = Loader::CreatePolicy.from_policy(nil, nil, Loader::Validate, logger: Rails.logger)

  context "when the policy parsed as an error" do
    adhoc_err = Exceptions::EnhancedPolicyError.new(
      original_error: nil,
      detail_message: "fake error"
    )
    it "reports a response with Invalid YAML status" do
      policy_result = PolicyResult.new(
        policy_version: nil,
        created_roles: nil,
        policy_parse: PolicyParse.new([], adhoc_err),
        diff: nil
      )
      response = mode.report(policy_result)

      expect(response['status']).to match("Invalid YAML")
      expect(response['errors'][0][:message]).to match(/fake error.*/)
    end
  end

  context "when the policy parsed with no error" do
    it "reports a response with Valid YAML status" do
      policy_result = PolicyResult.new(
        policy_version: nil,
        created_roles: nil,
        policy_parse: PolicyParse.new([], nil),
        diff: nil
      )
      response = mode.report(policy_result)

      expect(response['status']).to match("Valid YAML")
    end
  end
end
