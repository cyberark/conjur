# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(DB::Repository::Authenticator::Create) do
  let(:subject) do
    described_class.new(
      authenticator: create_authenticator_model(auth: authenticator_dict)
    )
  end

  let(:owner) { "rspec:policy:conjur/authn-jwt/auth1" }

  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')
  end

  let(:repo) do
    DB::Repository::AuthenticatorRepository.new
  end

  let(:variables) { { jwks_uri: "https://test" } }

  let(:authenticator_dict) do
    {
      type: "authn-jwt",
      service_id: "auth1",
      account: 'rspec',
      branch: 'conjur/authn-jwt',
      enabled: true,
      owner_id: owner,
      annotations: { description: "this is my base authenticator" },
      variables: variables
    }
  end

  def create_authenticator_model(auth:)
    AuthenticatorsV2::JwtAuthenticatorType.new(auth)
  end

  def expect_auth_in_policy?
    expect(::Resource["rspec:policy:conjur/authn-jwt/auth1"]).to_not be_nil

    expect(::Resource["rspec:webservice:conjur/authn-jwt/auth1"]).to_not be_nil
    expect(::Resource["rspec:webservice:conjur/authn-jwt/auth1"].owner_id)
      .to eq(owner)

    expect(::Resource["rspec:webservice:conjur/authn-jwt/auth1/status"]).to_not be_nil
    expect(::Resource["rspec:webservice:conjur/authn-jwt/auth1/status"].owner_id)
      .to eq(owner)

    expect(::Resource["rspec:group:conjur/authn-jwt/auth1/apps"]).to_not be_nil
    expect(::Resource["rspec:group:conjur/authn-jwt/auth1/apps"].owner_id)
      .to eq(owner)

    expect(::Resource["rspec:group:conjur/authn-jwt/auth1/operators"]).to_not be_nil
    expect(::Resource["rspec:group:conjur/authn-jwt/auth1/operators"].owner_id)
      .to eq(owner)

    expect(::Resource["rspec:variable:conjur/authn-jwt/auth1/jwks-uri"]).to_not be_nil
    expect(::Resource["rspec:variable:conjur/authn-jwt/auth1/jwks-uri"].owner_id)
      .to eq(owner)
  end

  describe('#call') do
    context 'given an auth dic' do
      before(:each) do
        ::Resource.create(
          resource_id: "rspec:policy:conjur/authn-jwt",
          owner_id: 'rspec:user:admin'
        )
        ::Role.create(role_id: "rspec:policy:conjur/authn-jwt")
      end
      it 'creates the authenticator' do
        response = subject.call
        expect(response.success?).to be(true)
        expect_auth_in_policy?
      end
      context 'authenticator already exisit' do
        it 'returns a failure response' do
          allow(::Resource).to receive(:create).and_raise(Sequel::UniqueConstraintViolation.new)
          response = subject.call 
          expect(response.success?).to be(false)
          expect(response.message).to eq("The authenticator already exists.")
        end
      end
      after(:each) do
        ::Resource["rspec:policy:conjur/authn-jwt"]&.destroy
        ::Role["rspec:policy:conjur/authn-jwt"]&.destroy
      end
    end
    context 'when root policy does not exisit' do
      it 'returns a failure response' do
        response = subject.call
        expect(response.success?).to be(false)
        expect(response.message).to eq("Policy 'conjur/authn-jwt' is required to create a new authenticator.")
      end
    end
  end
end
