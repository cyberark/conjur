# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::V2::Strategies') do
  let(:jwt) { double(raw_attributes: { claim_mapping: "alice" }) }
  let(:refresh_token) { 'kXMJFtgtaEpOGn0Zk2x15i8umXIWp4aqY1Mh7zscfGI' }
  let(:mapping) { "claim_mapping" }

  let(:authenticator) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
      account: "cucumber",
      service_id: "foo",
      redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
      provider_uri: "http://test",
      name: "foo",
      client_id: "ConjurClient",
      client_secret: 'client_secret',
      claim_mapping: mapping
    )
  end

  let(:client) do
    class_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:new).and_return(current_client)
    end
  end

  let(:current_client) do
    instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:get_token_with_code).and_return([jwt, nil])
    end
  end

  describe('::AuthzCode') do
    let(:strategy) do
      Authentication::AuthnOidc::V2::Strategies::AuthzCode.new(
        authenticator: authenticator,
        client: client
      )
    end

    describe('#callback') do
      context 'When a role_id matches the identity exist' do
        it 'returns the role' do
          role, headers_h = strategy.callback(nonce: 'nonce', code: 'code', code_verifier: 'foo')

          expect(role).to eq('alice')
          expect(headers_h).to be_empty
        end
      end

      context "when the claiming matching in the token doesn't match the jwt" do
        let(:mapping) { 'wrong_mapping' }
        it 'raises a `IdTokenClaimNotFoundOrEmpty` error' do
          expect { strategy.callback(code: 'code', nonce: 'nonce', code_verifier: 'foo') }
            .to raise_error(Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty)
        end
      end

      context 'when required parameters are missing' do
        context 'when code is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect { strategy.callback(nonce: 'nonce', code_verifier: 'foo') }
              .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
        context 'when nonce is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect { strategy.callback(code: 'code', code_verifier: 'foo') }
              .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
        context 'when code_verifier is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect { strategy.callback(nonce: 'nonce', code: 'code') }
              .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
      end

      context 'when refresh token flow is enabled' do
        let(:current_client) do
          instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
            allow(double).to receive(:get_token_with_code).and_return([jwt, refresh_token])
            allow(double).to receive(:get_token_with_refresh_token).and_return([jwt, refresh_token])
          end
        end

        context 'when a role_id matches the identity exist' do
          it 'returns the role and refresh token' do
            expect(current_client).to receive(:get_token_with_code)
              .with(:nonce => 'nonce', :code => 'code', :code_verifier => 'foo')
            role, headers_h = strategy.callback(nonce: 'nonce', code: 'code', code_verifier: 'foo')
  
            expect(role).to eq("alice")
            expect(headers_h).to include('X-OIDC-Refresh-Token' => refresh_token)
          end
        end
      end
    end
  end

  describe('::RefreshToken') do
    let(:current_client) do
      instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
        allow(double).to receive(:get_token_with_refresh_token).and_return([jwt, refresh_token])
      end
    end

    let(:strategy) do
      Authentication::AuthnOidc::V2::Strategies::RefreshToken.new(
        authenticator: authenticator,
        client: client
      )
    end

    describe('#callback') do
      context 'when a role_id matches the identity exist' do
        it 'returns the role' do
          role, headers_h = strategy.callback(nonce: 'nonce', refresh_token: 'refresh_token')

          expect(role).to eq('alice')
          expect(headers_h).to include('X-OIDC-Refresh-Token' => refresh_token)
        end
      end

      context 'when required parameters are missing' do
        context 'when refresh_token is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect { strategy.callback(nonce: 'nonce') }
              .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
        context 'when nonce is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect { strategy.callback(refresh_token: 'refresh_token') }
              .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
      end
    end
  end

  describe('::Logout') do
    let(:current_client) do
      instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
        allow(double).to receive(:get_token_with_refresh_token).and_return([jwt, refresh_token])
        allow(double).to receive(:end_session).and_return(URI('https://oidc-provider.org/logout'))
      end
    end

    let(:strategy) do
      Authentication::AuthnOidc::V2::Strategies::Logout.new(
        authenticator: authenticator,
        client: client
      )
    end

    describe('#callback') do
      it 'returns an OIDC session termination URI' do
        uri = strategy.callback(refresh_token: 'refresh_token', nonce: 'nonce', state: 'state', redirect_uri: 'https://conjur.org/redir')

        expect(uri.to_s).to eq('https://oidc-provider.org/logout')
      end

      context 'when required parameters are missing' do
        context 'when refresh_token is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect do
              strategy.callback(
                nonce: 'nonce',
                state: 'state',
                redirect_uri: 'https://redir.com/here'
              )
            end.to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
        context 'when nonce is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect do
              strategy.callback(
                refresh_token: 'refresh_token',
                state: 'state',
                redirect_uri: 'https://redir.com/here'
              )
            end.to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
        context 'when state is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect do
              strategy.callback(
                refresh_token: 'refresh_token',
                nonce: 'nonce',
                redirect_uri: 'https://redir.com/here'
              )
            end.to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
        context 'when redirect_uri is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect do
              strategy.callback(
                refresh_token: 'refresh_token',
                nonce: 'nonce',
                state: 'state'
              )
            end.to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
      end
    end
  end
end
