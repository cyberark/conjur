# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::Webservices') do
  let(:two_authenticator_env) { "authn-one, authn-two" }

  context "An ENV containing CONJUR_AUTHENTICATORS" do
    it "whitelists exactly those authenticators as webservices" do
      services = ::Authentication::Webservices.from_string(
        "my-acct",
        two_authenticator_env
      ).map(&:name)

      expect(services).to eq(%w[authn-one authn-two])
    end
  end
end
