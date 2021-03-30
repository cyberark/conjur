# frozen_string_literal: true

RSpec.describe(Authentication::AuthnOidc::ValidateStatus) do
  let(:authenticator_name) { "authn-oidc" }
  let(:account) { "my-acct" }
  let(:service) { "my-service" }

  include_context "fetch secrets", %w[provider-uri id-token-user-property]

  let(:test_oidc_discovery_error) { "test-oidc-discovery-error" }

  def mock_discover_identity_provider(is_successful:)
    double('discovery-provider').tap do |discover_provider|
      if is_successful
        allow(discover_provider).to receive(:call)
      else
        allow(discover_provider).to receive(:call)
          .and_raise(test_oidc_discovery_error)
      end
    end
  end

  context "Required variables exist and have values" do
    context "and Oidc provider is responsive" do
      subject do
        Authentication::AuthnOidc::ValidateStatus.new(
          discover_identity_provider: mock_discover_identity_provider(is_successful: true)
        ).call(
          account: account,
          service_id: service
        )
      end

      it "validates without errors" do
        expect { subject }.to_not raise_error
      end

      it_behaves_like "it fails when variable is missing or has no value", "provider-uri"
      it_behaves_like "it fails when variable is missing or has no value", "id-token-user-property"
    end

    context "and Oidc provider is not responsive" do
      subject do
        Authentication::AuthnOidc::ValidateStatus.new(
          discover_identity_provider: mock_discover_identity_provider(is_successful: false)
        ).call(
          account: account,
          service_id: service
        )
      end

      it "raises the error raised by discover_identity_provider" do
        expect { subject }.to raise_error(test_oidc_discovery_error)
      end
    end
  end
end
