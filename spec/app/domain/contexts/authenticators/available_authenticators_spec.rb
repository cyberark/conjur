# frozen_string_literal: true

require 'spec_helper'
describe Contexts::Authenticators::AvailableAuthenticators do
  let(:endpoint) { double(authorization_endpoint: '"http://test"') }
  let(:foo_id) { "rspec:webservice:conjur/authn-oidc/foo" }
  let(:bar_id) { "rspec:webservice:conjur/authn-oidc/bar" }
  let(:redirect_uri) do
    "\"http://test\"?client_id=&response_type=&scope=" \
      "&state=&nonce=&redirect_uri="
  end

  let(:foo) do
    Authenticator::OidcAuthenticator
      .new(account: "cucumber",
           service_id: "foo",
           provider_uri: "http://test",
           name: "foo")
  end

  let(:bar) do
    Authenticator::OidcAuthenticator
      .new(account: "cucumber",
           service_id: "bar",
           provider_uri: "http://test",
           name: "bar")
  end

  let(:authenticators) {[foo, bar]}

  let(:res) do
    [{ redirect_uri: redirect_uri,
       service_id: "foo" },
     { redirect_uri: redirect_uri,
       service_id: "bar" }]
  end

  let(:repository) do
    instance_double(DB::Repository::AuthenticatorRepository)
      .tap do |double|
      allow(double).to receive(:find_all).and_return(response)
    end
  end

  let(:resource) do
    instance_double(::Resource).tap do |double|
      allow(double).to receive(:[]).with({ resource_id: foo_id })
        .and_return(foo_resource)
      allow(double).to receive(:[]).with({ resource_id: bar_id })
        .and_return(bar_resource)
    end
  end

  let(:foo_resource) do
    instance_double(::Resource).tap do |double|
      allow(double).to receive(:resource_id).and_return(foo_id)
    end
  end

  let(:bar_resource) do
    instance_double(::Resource).tap do |double|
      allow(double).to receive(:resource_id).and_return(bar_id)
    end
  end

  let(:role) do
    instance_double(::Role).tap do |double|
      allow(double).to receive(:allowed_to?).with('authenticate', foo_resource)
        .and_return(foo_permission)
      allow(double).to receive(:allowed_to?).with('authenticate', bar_resource)
        .and_return(bar_permission)
    end
  end

  let(:util) do
    instance_double(::Authentication::Util::OidcUtil).tap do |double|
      allow(double).to receive(:discovery_information).and_return(endpoint)
    end
  end

  let(:handler) do
    Authentication::Handler::OidcAuthenticationHandler.new(
      oidc_util: util
    )
  end

  let(:available_authenticators) do
    Contexts::Authenticators::AvailableAuthenticators.new(
      repository: repository,
      handler: handler,
      resource: resource
    )
  end

  describe '.call' do
    before do
      allow(foo).to receive(:resource_id).and_return(foo_id)
      allow(bar).to receive(:resource_id).and_return(bar_id)
    end

    context 'when no authenticators exist' do
      let(:response) { [] }
      let(:foo_permission) { false }
      let(:bar_permission) { false }
      it 'returns an empty set' do
        expect(available_authenticators.call(account: 'foo', role: role))
          .to eq([])
      end
    end

    context 'when multiple permitted authenticators exist' do
      let(:response) { authenticators }
      let(:foo_permission) { true }
      let(:bar_permission) { true }
      it 'returns an array of authenticators' do
        expect(available_authenticators.call(account: 'foo', role: role))
          .to eq(res)
      end
    end

    context 'when multiple authenticators exist and' \
             'user can only authnticate with one' do
      let(:response) { authenticators }
      let(:foo_permission) { true }
      let(:bar_permission) { false }
      it 'returns a partial set of the authenticators' do
        expect(available_authenticators.call(account: 'foo', role: role))
          .to eq([{ redirect_uri: redirect_uri,
                    service_id: "foo" }])
      end
    end

    context 'when multiple authenticators exist and user is not permitted' do
      let(:response) { authenticators }
      let(:foo_permission) { false }
      let(:bar_permission) { false }
      it 'returns an empty set' do
        expect(available_authenticators.call(account: 'foo', role: role))
          .to eq([])
      end
    end

    context 'when no authenticators exist and user is not permitted' do
      let(:response) { [] }
      let(:foo_permission) { false }
      let(:bar_permission) { false }
      it 'returns an empty set' do
        expect(available_authenticators.call(account: 'foo', role: role))
          .to eq([])
      end
    end
  end
end
