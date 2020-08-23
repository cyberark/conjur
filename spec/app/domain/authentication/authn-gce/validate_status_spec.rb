# frozen_string_literal: true

RSpec.describe Authentication::AuthnGce::ValidateStatus do

  let(:test_gce_discovery_error) { "test-gce-discovery-error" }

  def mock_discover_identity_provider(is_successful:)
    double('discovery-provider').tap do |discover_provider|
      if is_successful
        allow(discover_provider).to receive(:call)
      else
        allow(discover_provider).to receive(:call)
                                      .and_raise(test_gce_discovery_error)
      end
    end
  end

  context "GCE Provider is responsive" do
    subject do
      Authentication::AuthnGce::ValidateStatus.new(
        discover_identity_provider: mock_discover_identity_provider(is_successful: true)
      ).call
    end

    it "validates without errors" do
      expect { subject }.to_not raise_error
    end
  end

  context "GCE Provider is not responsive" do
    subject do
      Authentication::AuthnGce::ValidateStatus.new(
        discover_identity_provider: mock_discover_identity_provider(is_successful: false)
      ).call
    end

    it "raises the error raised by discover_identity_provider" do
      expect { subject }.to raise_error(test_gce_discovery_error)
    end

  end
end
