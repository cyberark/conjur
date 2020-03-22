# frozen_string_literal: true

RSpec.describe Authentication::AuthnAzure::ValidateStatus do

  let(:authenticator_name) { "authn-azure" }
  let(:account) { "my-acct" }
  let(:service) { "my-service" }

  include_context "fetch secrets", %w(provider-uri)

  let(:test_azure_discovery_error) { "test-azure-discovery-error" }

  def mock_discover_identity_provider(is_successful:)
    double('discovery-provider').tap do |discover_provider|
      if is_successful
        allow(discover_provider).to receive(:call)
      else
        allow(discover_provider).to receive(:call)
                                      .and_raise(test_azure_discovery_error)
      end
    end
  end

  context "Required variables exist and have values" do
    context "and Azure provider is responsive" do
      subject do
        Authentication::AuthnAzure::ValidateStatus.new(
          discover_identity_provider: mock_discover_identity_provider(is_successful: true)
        ).call(
          account:    account,
          service_id: service
        )
      end

      it "validates without errors" do
        expect { subject }.to_not raise_error
      end

      it_behaves_like "it fails when variable is missing or has no value", "provider-uri"
    end

    context "and Azure provider is not responsive" do
      subject do
        Authentication::AuthnAzure::ValidateStatus.new(
          discover_identity_provider: mock_discover_identity_provider(is_successful: false)
        ).call(
          account:    account,
          service_id: service
        )
      end

      it "raises the error raised by discover_identity_provider" do
        expect { subject }.to raise_error(test_azure_discovery_error)
      end

    end
  end
end
