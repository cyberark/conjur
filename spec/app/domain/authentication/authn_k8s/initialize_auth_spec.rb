# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnK8s::InitializeK8sAuth) do
  include_context "auth data"

  let(:account) {  "account" }
  let(:service_id) { "test" }

  subject do
    Authentication::Default::InitializeDefaultAuth.new(
      secret: secret
    ).(
      conjur_account: account,
      service_id: service_id,
      auth_data: auth_data
    )
  end

  context "Given we initialize a K8s authenticator" do

    it("correctly loads the secrets and initializes the ca repo") do

    end

    context "the json body is empty" do

    end

    context "the json body is nil" do

    end

  end
end
