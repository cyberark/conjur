# frozen_string_literal: true

shared_context "fetch secrets" do

  let(:test_fetch_secrets_error) { "test-fetch-secrets-error" }

  let(:mocked_secret) do
    double('Secret').tap do |secret|
      allow(secret).to receive(:value).and_return("mocked-secret")
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

  def mock_fetch_secrets(is_successful:, fetched_secrets:)
    double('fetch_secrets').tap do |fetch_secrets|
      if is_successful
        allow(fetch_secrets).to receive(:call)
                                  .and_return(fetched_secrets)
      else
        allow(fetch_secrets).to receive(:call)
                                  .and_raise(test_fetch_secrets_error)
      end
    end
  end
end

shared_examples_for "it fails when variable is missing or has no value" do |variable_name|
  it "fails when variable is missing" do
    allow(Resource).to receive(:[])
                         .with(/#{account}:variable:conjur\/#{authenticator_name}\/#{service}\/#{variable_name}/)
                         .and_return(nil)

    expect { subject }.to raise_error(Errors::Conjur::RequiredResourceMissing)
  end

  it "fails when variable has no value" do
    allow(Resource).to receive(:[])
                         .with(/#{account}:variable:conjur\/#{authenticator_name}\/#{service}\/#{variable_name}/)
                         .and_return(resource_without_value)

    expect { subject }.to raise_error(Errors::Conjur::RequiredSecretMissing)
  end
end