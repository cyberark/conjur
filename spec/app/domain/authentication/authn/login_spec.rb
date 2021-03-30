# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::Authn::Login') do
  include_context "authn setup"

  context "An Authn authenticator" do
    context "that receives a login request" do
      context "with valid credentials" do
        subject do
          ::Authentication::Authn::Login.new(
            role_cls: role_cls,
            credentials_cls: credentials_cls
          ).call(
            authenticator_input: input
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end

        it "returns a non nil value" do
          expect(subject).not_to eq(nil)
        end
      end

      context "with a non-existing role" do
        subject do
          ::Authentication::Authn::Login.new(
            role_cls: role_cls,
            credentials_cls: non_existing_role_credentials
          ).call(
            authenticator_input: input
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end

        it "returns nil" do
          expect(subject).to eq(nil)
        end
      end
    end
  end
end
