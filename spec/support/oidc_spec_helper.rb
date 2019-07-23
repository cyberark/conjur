# frozen_string_literal: true

shared_context "oidc setup" do

  let(:oidc_authenticator_name) { "authn-oidc-test" }
  let(:account) { "my-acct" }
  let(:service) { "my-service" }

  ####################################
  # TokenFactory double
  ####################################

  let (:a_new_token) { 'A NICE NEW TOKEN' }

  let (:token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end

  ####################################
  # secrets mocks
  ####################################

  let (:mocked_secret) do
    double('Secret').tap do |secret|
      allow(secret).to receive(:value).and_return("mocked-secret")
    end
  end

  let (:mocked_resource) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(mocked_secret)
    end
  end

  let (:resource_without_value) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(nil)
    end
  end

  let (:mocked_id_token_secret) do
    double('Secret').tap do |secret|
      allow(secret).to receive(:value).and_return("id_token_username_field")
    end
  end

  let (:mocked_id_token_resource) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(mocked_id_token_secret)
    end
  end

  ####################################
  # validator mocks
  ####################################

  let (:mocked_security_validator) { double("MockSecurityValidator") }
  let (:mocked_origin_validator) { double("MockOriginValidator") }

  before(:each) do
    allow(Resource).to receive(:[])
                         .with(/#{account}:variable:conjur\/authn-oidc/)
                         .and_return(mocked_resource)

    allow(mocked_security_validator).to receive(:call)
                                          .and_return(true)

    allow(mocked_origin_validator).to receive(:call)
                                        .and_return(true)
  end
end

shared_examples_for "it fails when variable is missing or has no value" do |variable|
  it "fails when variable is missing" do
    allow(Resource).to receive(:[])
                         .with(/#{account}:variable:conjur\/authn-oidc\/#{service}\/#{variable}/)
                         .and_return(nil)

    expect { subject }.to raise_error(Errors::Conjur::RequiredResourceMissing)
  end

  it "fails when variable has no value" do
    allow(Resource).to receive(:[])
                         .with(/#{account}:variable:conjur\/authn-oidc\/#{service}\/#{variable}/)
                         .and_return(resource_without_value)

    expect { subject }.to raise_error(Errors::Conjur::RequiredSecretMissing)
  end
end

shared_examples_for "raises an error when security validation fails" do
  it 'raises an error when security validation fails' do
    allow(mocked_security_validator).to receive(:call)
                                          .and_raise('FAKE_SECURITY_ERROR')

    expect { subject }.to raise_error(
                            /FAKE_SECURITY_ERROR/
                          )
  end
end

shared_examples_for "raises an error when origin validation fails" do
  it "raises an error when origin validation fails" do
    allow(mocked_origin_validator).to receive(:call)
                                        .and_raise('FAKE_ORIGIN_ERROR')

    expect { subject }.to raise_error(
                            /FAKE_ORIGIN_ERROR/
                          )
  end
end
