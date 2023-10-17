# frozen_string_literal: true

RSpec.describe(Authentication::OAuth::DiscoverIdentityProvider) do
  let(:test_provider_uri) { "test-provider-uri" }
  let(:test_error) { "test-error" }
  let(:mock_provider) { "test-provider" }

  def mock_discovery_provider(error:)
    double('discovery_provider').tap do |discovery_provider|
      if error
        allow(discovery_provider).to receive(:discover!)
          .and_raise(error)
      else
        allow(discovery_provider).to receive(:discover!)
          .and_return(mock_provider)
      end
    end
  end

  context "A discoverable identity provider" do
    subject do
      Authentication::OAuth::DiscoverIdentityProvider.new(
        open_id_discovery_service: mock_discovery_provider(error: nil)
      ).call(
        provider_uri: test_provider_uri,
        ca_cert: nil
      )
    end

    it "does not raise an error" do
      expect { subject }.to_not raise_error
    end

    it "returns the discovered provider" do
      expect(subject).to eq(mock_provider)
    end
  end

  context "A non-discoverable identity provider" do
    context "that fails on a timeout error" do
      subject do
        Authentication::OAuth::DiscoverIdentityProvider.new(
          open_id_discovery_service: mock_discovery_provider(error: Errno::ETIMEDOUT)
        ).call(
          provider_uri: test_provider_uri,
          ca_cert: nil
        )
      end

      it "returns a ProviderDiscoveryTimeout error" do
        expect { subject }.to raise_error(Errors::Authentication::OAuth::ProviderDiscoveryTimeout)
      end

      context "that fails on a general error" do
        subject do
          Authentication::OAuth::DiscoverIdentityProvider.new(
            open_id_discovery_service: mock_discovery_provider(error: test_error)
          ).call(
            provider_uri: test_provider_uri,
            ca_cert: nil
          )
        end

        it "returns a ProviderDiscoveryFailed error" do
          expect { subject }.to raise_error(Errors::Authentication::OAuth::ProviderDiscoveryFailed)
        end
      end
    end
  end
end
