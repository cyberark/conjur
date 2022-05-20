# frozen_string_literal: true

require 'spec_helper'

describe Contexts::Authenticators::AvailableAuthenticators do
  let(:repository) do
    instance_double(DB::Repository::AuthenticatorRepository).tap do |double|
      allow(double).to receive(:find_all).and_return(find_all)
    end
  end

  let(:handler) do
    instance_double(Authentication::Handler::OidcAuthenticationHandler).tap do |double|
      allow(double).to receive(:generate_login_url).and_return('redirect_url')
    end
  end
  let(:available_authenticators) do
    Contexts::Authenticators::AvailableAuthenticators.new(
      repository: repository,
      handler: handler
    )
  end

  describe '.call' do
    context 'when no authenticators exist' do
      let(:find_all) {[]}
      it 'returns an empty set' do
        expect(available_authenticators.call(account: 'foo', role: 'bar')).to eq([])
      end
    end

    context 'when multiple permitted authenticators exist' do
      let(:find_all) do
        [
          Authenticator::OidcAuthenticator.new(account: "rspec", service_id: "foo"),
          Authenticator::OidcAuthenticator.new(account: "rspec", service_id: "bar"),
          Authenticator::OidcAuthenticator.new(account: "rspec", service_id: "baz")
        ]
      end

      let(:owner) { Role.new(role_id: 'rspec:user:foo') }
      let(:foo) { Resource.new(resource_id: 'rspec:webservice:conjur/authn-oidc/foo', owner_id: owner) }
      let(:bar) { Resource.new(resource_id: 'rspec:webservice:conjur/authn-oidc/bar', owner_id: owner) }
      let(:baz) { Resource.new(resource_id: 'rspec:webservice:conjur/authn-oidc/baz', owner_id: owner) }

      it 'returns permitted authenticators' do
        # Mock Role lookup
        allow(Role).to receive(:[]).with(foo.id).and_return(foo)
        allow(Role).to receive(:[]).with(bar.id).and_return(bar)
        allow(Role).to receive(:[]).with(baz.id).and_return(baz)

        # Mock `allowed_to?` to only allow a single authenticator to be choosen
        allow(owner).to receive(:allowed_to?).with('authenticate', foo).and_return(false)
        allow(owner).to receive(:allowed_to?).with('authenticate', bar).and_return(true)
        allow(owner).to receive(:allowed_to?).with('authenticate', baz).and_return(false)

        expect(
          available_authenticators.call(
            account: 'rspec',
            role: owner
          )
        ).to eq([{
          service_id: 'bar',
          redirect_uri: 'redirect_url'
        }])
      end
    end
  end
end
