# frozen_string_literal: true

shared_context "oidc setup" do
  let(:authenticator_name) { "authn-oidc" }
  let(:account) { "my-acct" }
  let(:service) { "my-service" }

  ####################################
  # TokenFactory double
  ####################################

  let(:a_new_token) { 'A NICE NEW TOKEN' }

  let(:mocked_token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end

  ####################################
  # oidc secrets mocks
  ####################################

  let(:mocked_id_token_secret) do
    double('Secret').tap do |secret|
      allow(secret).to receive(:value).and_return("id_token_username_field")
    end
  end

  let(:mocked_id_token_resource) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(mocked_id_token_secret)
    end
  end

  before(:each) do
    allow(Resource).to(
      receive(:[]).with(%r{#{account}:variable:conjur/authn-oidc})
        .and_return(mocked_resource)
    )
  end
end
