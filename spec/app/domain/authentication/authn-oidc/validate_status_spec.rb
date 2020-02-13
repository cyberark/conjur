# frozen_string_literal: true

RSpec.describe Authentication::AuthnOidc::ValidateStatus do

  include_context "fetch secrets"

  let (:test_account) { "test-account" }
  let (:test_service_id) { "test-service-id" }
  let (:test_oidc_discovery_error) { "test-oidc-discovery-error" }

  let (:oidc_authenticator_secrets) do
    {
      "provider-uri" => "test-uri",
      "id-token-user-property" => "test-property"
    }
  end

  def mock_discover_oidc_provider(is_successful:)
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
          fetch_authenticator_secrets: mock_fetch_secrets(
                                         is_successful: true,
                                         fetched_secrets: oidc_authenticator_secrets
                                       ),
          discover_oidc_provider: mock_discover_oidc_provider(is_successful: true)
        ).call(
          account: test_account,
            service_id: test_service_id
        )
      end

      it "validates without errors" do
        expect { subject }.to_not raise_error
      end
    end

    context "and Oidc provider is not responsive" do

      subject do
        Authentication::AuthnOidc::ValidateStatus.new(
          fetch_authenticator_secrets: mock_fetch_secrets(
                                         is_successful: true,
                                         fetched_secrets: oidc_authenticator_secrets
                                       ),
          discover_oidc_provider: mock_discover_oidc_provider(is_successful: false)
        ).call(
          account: test_account,
            service_id: test_service_id
        )
      end

      it "raises the error raised by discover_oidc_provider" do
        expect { subject }.to raise_error(test_oidc_discovery_error)
      end

    end
  end

  context "Required variables do not exist or does not have value" do
    subject do
      Authentication::AuthnOidc::ValidateStatus.new(
        fetch_authenticator_secrets: mock_fetch_secrets(
                                       is_successful: false,
                                       fetched_secrets: oidc_authenticator_secrets
                                     ),
        discover_oidc_provider: mock_discover_oidc_provider(is_successful: true)
      ).call(
        account: test_account,
          service_id: test_service_id
      )
    end

    it "raises the error raised by fetch_authenticator_secrets" do
      expect { subject }.to raise_error(test_fetch_secrets_error)
    end
  end
end