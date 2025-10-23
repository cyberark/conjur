# frozen_string_literal: true

require 'spec_helper'

describe Authenticators::Delete do
  let(:subject) do
    Authenticators::Delete.new(
      authn_repo: authn_repo
    )
  end
  let(:branch){conjur/authn-jwt}
  let(:webservice_id) {"rspec:webservice:conjur/authn-jwt/test-service"}
  let(:policy_id) {"rspec:policy:conjur/authn-jwt/test-service"}

  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')
    Role.find_or_create(role_id: 'rspec:user:owner')
  end

  let(:request) do
    instance_double(ActionDispatch::Request, ip: "127.0.0.1", headers: { "X-Request-ID" => "abc123" })
  end

  let(:authenticators) do
    ::AuthenticatorsV2::JwtAuthenticatorType.new(
      {
        type: 'authn-jwt',
        account: 'rspec',
        owner_id: 'rspec:user:owner',
        service_id: 'test-service' 
      }
    )
  end

  let(:response) do
    Responses::Success.new(authenticators)
  end

  let(:authn_repo) do
    double(::DB::Repository::AuthenticatorRepository).tap do |double|
      allow(double).to receive(:new).and_return(current_repo)
    end
  end

  let(:current_repo) do
    instance_double(::DB::Repository::AuthenticatorRepository).tap do |double|
      allow(double).to receive(:find).and_return(response)
      allow(double).to receive(:delete).with(policy_id: policy_id).and_return(policy_id)
    end
  end

  describe '#delete' do
    let(:body) {{ enabled: true }}
    before do
      AuthenticatorController::Current.user = Role.find(role_id: 'rspec:user:admin')
      AuthenticatorController::Current.request = request
    end
    context 'when called with type, account, and service_id' do
      it 'deletes the authenticator and returns the policy_id' do
        allow(::Resource).to receive(:[]).with(policy_id).and_return("found")
        allow_any_instance_of(::Role).to receive(:allowed_to?).with('delete', "found").and_return(true)
        res = subject.call(type: 'authn-jwt', account: 'cucumber', service_id: 'test-service')
        expect(res.result).to eq(policy_id)
      end
    end
    context 'when user attempts to delete without the delete pemrisison' do
      it 'returns an unauthorized error' do
        allow(::Resource).to receive(:[]).with(policy_id).and_return("found")
        allow_any_instance_of(::Role).to receive(:allowed_to?).with('delete', "found").and_return(false)
        res = subject.call(type: 'authn-jwt', account: 'cucumber', service_id: 'test-service')
        expect(res.message).to eq("Unauthorized")
      end
    end
    context 'When the authenticator is not found' do
      let(:response) do
        Responses::Failure.new(
          "Authenticator: 'test-service' not found in account 'rspec'",
          status: :not_found,
          exception: Errors::Authentication::Security::WebserviceNotFound.new(webservice_id)
        )
      end
      it 'returns the authenticator from the repository' do
        res = subject.call(type: 'authn-jwt', account: 'cucumber', service_id: 'test-service')
        expect(res.message).to eq("Authenticator: 'test-service' not found in account 'rspec'")
      end
    end
  end
end
