# frozen_string_literal: true

# To use this helper you need to:
# 1. Define a a memoized helper method for:
#   a. account
#   b. authenticator_name
#   c. service
# 2. Provide a list of required secrets
#
# For example:
#   let(:authenticator_name) { "#{authenticator_name}" }
#   let(:account) { "my-acct" }
#   let(:service) { "my-service" }
#
#   include_context "fetch secrets", %w(provider-uri id-token-user-property)
#
shared_context "fetch secrets" do |required_secrets|

  let(:mocked_secret) do
    double('Secret').tap do |secret|
      # unfreezing the secret for authn-azure tests
      allow(secret).to receive(:value).and_return(+"mocked-secret")
    end
  end

  let(:mocked_resource) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(mocked_secret)
    end
  end

  let(:resource_without_value) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(nil)
    end
  end

  before(:each) do
    required_secrets.each { |secret_name|
      allow(Resource).to(
        receive(:[]).with(
          /#{account}:variable:conjur\/#{authenticator_name}\/#{service}\/#{secret_name}/
        ).and_return(mocked_resource)
      )
    }
  end
end

shared_examples_for(
  "it fails when variable is missing or has no value"
) do |variable|

  context 'when variable is missing' do
    let(:audit_success) { false }

    it "fails" do
      allow(Resource).to(
        receive(:[]).with(
          /#{account}:variable:conjur\/#{authenticator_name}\/#{service}\/#{variable}/
        ).and_return(nil)
      )

      expect { subject }.to raise_error(Errors::Conjur::RequiredResourceMissing)
    end
  end

  context 'when variable has no value' do
    let(:audit_success) { false }

    it "fails" do
      allow(Resource).to(
        receive(:[]).with(
          /#{account}:variable:conjur\/#{authenticator_name}\/#{service}\/#{variable}/
        ).and_return(resource_without_value)
      )

      expect { subject }.to(
        raise_error(Errors::Conjur::RequiredSecretMissing)
      )
    end
  end
end
