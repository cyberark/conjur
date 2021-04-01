# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Security::ValidateAccountExists) do
  include_context "security mocks"

  context "An existing account" do
    subject do
      Authentication::Security::ValidateAccountExists.new(
        role_class: mock_role_class
      ).call(
        account: test_account
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A non-existing account" do
    subject do
      Authentication::Security::ValidateAccountExists.new(
        role_class: mock_role_class
      ).call(
        account: non_existing_account
      )
    end

    it "raises an AccountNotDefined error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::AccountNotDefined)
    end
  end
end
