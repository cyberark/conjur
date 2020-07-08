# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::Authn::Authenticator' do
  include_context "authn setup"

  context "An Authn authenticator" do
    context "that receives an authentication request" do
      context "with valid credentials" do
        subject do
          ::Authentication::Authn::Authenticator.new(
            role_cls:        role_cls,
            credentials_cls: valid_api_key_credentials
          ).call(
            authenticator_input: input
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end

        it "returns true" do
          expect(subject).to eq(true)
        end
      end

      context "with a non-existing role" do
        subject do
          ::Authentication::Authn::Authenticator.new(
            role_cls:        role_cls,
            credentials_cls: non_existing_role_credentials
          ).call(
            authenticator_input: input
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end

        it "returns false" do
          expect(subject).to eq(false)
        end
      end

      context "with an invalid api key" do
        subject do
          ::Authentication::Authn::Authenticator.new(
            role_cls:        role_cls,
            credentials_cls: invalid_api_key_credentials
          ).call(
            authenticator_input: input
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end

        it "returns false" do
          expect(subject).to eq(false)
        end
      end
    end
  end
end
