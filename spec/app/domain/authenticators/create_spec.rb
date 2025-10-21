# frozen_string_literal: true

require 'spec_helper'

describe Authenticators::Create do
  let(:subject) do
    Authenticators::Create.new(
      authn_repo: authn_repo,
      factory: factory,
      request_mapper: Authenticators::RequestMapper.new(
        validator: validator
      )
    )
  end
  let(:branch){conjur/authn-jwt}
  let(:webservice_id) {"rspec:webservice:conjur/authn-jwt/test-service"}
  let(:policy_id) {"rspec:policy:conjur/authn-jwt/test-service"}
  let(:authenticators_to_h) do 
    { 
      branch: "conjur/authn-jwt",
      enabled: true,
      name: "test-service",
      data: {},
      owner: {
        id: "owner", 
        kind: "user"
      },
      type: "jwt"
    }
  end

  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')
    Role.find_or_create(role_id: 'rspec:user:owner')
  end

  let(:request) do
    instance_double(ActionDispatch::Request, ip: "127.0.0.1", headers: { "X-Request-ID" => "abc123" })
  end

  let(:factory) do
    instance_double(AuthenticatorsV2::AuthenticatorTypeFactory).tap do |double|
      allow(double).to receive(:call).and_return(Responses::Success.new(authenticators))
    end
  end

  let(:validator) do
    instance_double(Authenticators::Validator).tap do |double|
      allow(double).to receive(:call).and_return(nil)
    end
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
      allow(double).to receive(:create).and_return(response)
    end
  end

  describe '#call' do
    let(:body) do
      {
        type: 'authn-jwt',
        account: 'rspec',
        branch: 'conjur/authn-jwt',
        service_id: 'test-service' 
      }
    end
    let(:resource_visible){ true }
    let(:owner_visible){ true }
    let(:create_permission){ true }
    let(:policy_id){ "rspec:policy:conjur/authn-jwt" }
    
    before do
      AuthenticatorController::Current.user = Role.find(role_id: 'rspec:user:admin')
      AuthenticatorController::Current.request = request

      allow(::Resource).to receive(:[]).with(policy_id)
        .and_return(Resource.find_or_create(resource_id: policy_id, owner_id: "rspec:user:owner"))
      allow(::Resource).to receive(:[]).with("rspec:user:owner")
        .and_return(Resource.find_or_create(resource_id: "rspec:user:owner", owner_id: "rspec:user:owner"))
      
      allow_any_instance_of(::Role).to receive(:allowed_to?)
        .with(:create, Resource[policy_id]).and_return(create_permission)
      
      allow_any_instance_of(::Resource).to receive(:visible_to?)
        .with(Role[role_id: 'rspec:user:admin']).and_return(resource_visible)
      
      allow(::Resource["rspec:user:owner"]).to receive(:visible_to?)
        .with(Role[role_id: 'rspec:user:admin']).and_return(owner_visible)
    end

    context 'When given a valid request' do
      it 'creates the authenticator' do
        res = subject.call(body, 'rspec')
        expect(res.result.to_h).to eq(authenticators_to_h)
      end
    end
    context 'when the webservice policy isnt visisble to the current user' do
      let(:resource_visible){ false }
      it 'returns a not_found failure response' do
        res = subject.call(body, 'rspec')
        expect(res.message).to eq("#{policy_id} not found in account rspec")
      end
    end
    context 'when the owner of the policy isnt visisble to the current user' do
      let(:owner_visible){ false }
      it 'returns a not_found failure response' do
        res = subject.call(body, 'rspec')
        expect(res.message).to eq("rspec:user:owner not found in account rspec")
      end
    end
    context 'When user doesnt have create permissions for the authenticator branch' do
      let(:create_permission){ false }
      it 'returns a forbidden' do
        expect{subject.call(body, 'rspec')}.to raise_error("Forbidden")
      end
    end
  end
end
