# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::V2::Strategy') do
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
      allow(double).to receive(:exchange_code_for_tokens).and_return({
        id_token: jwt, refresh_token: refresh_token
      })
      allow(double).to receive(:exchange_refresh_token_for_tokens).and_return({
        id_token: jwt, refresh_token: refresh_token
      })
    end
  end

  let(:strategy) do
    Authentication::AuthnOidc::V2::Strategy.new(
      authenticator: authenticator,
      client: client
    )
  end

  describe('#callback') do
    context 'when both code and refresh_token are included in request' do
      it 'raises a `MultipleXorRequestParams` error' do
        expect { strategy.callback(code: 'code', refresh_token: 'refresh_token') }
          .to raise_error(Errors::Authentication::RequestBody::BadXorCombination)
      end
    end

    context 'when both code and refresh_token are missing from request' do
      it 'raises a `MultipleXorRequestParams` error' do
        expect { strategy.callback({}) }
          .to raise_error(Errors::Authentication::RequestBody::BadXorCombination)
      end
    end

    context 'when authenticating with valid authorization code' do
      context 'when valid nonce and code_verifier arguments are included' do
        context 'when a role_id matching the identity exists' do
          it 'returns the role' do
            identity_and_headers = strategy.callback(
              code: 'code',
              nonce: 'nonce',
              code_verifier: 'foo'
            )

            expect(identity_and_headers[:identity]).to eq('alice')
            expect(identity_and_headers[:headers]).to include(
              'X-OIDC-Refresh-Token' => refresh_token
            )
          end
        end

        context "when the claiming matching in the token doesn't match the jwt" do
          let(:mapping) { 'wrong_mapping' }
          it 'raises a `IdTokenClaimNotFoundOrEmpty` error' do
            expect { strategy.callback(code: 'code', nonce: 'nonce', code_verifier: 'foo') }
              .to raise_error(Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty)
          end
        end
      end

      context 'when required parameters are missing' do
        context 'when nonce is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect { strategy.callback(code: 'code', code_verifier: 'foo') }
              .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
        context 'when code_verifier is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect { strategy.callback(code: 'code', nonce: 'nonce') }
              .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
      end
    end

    context 'when authenticating with a valid refresh token' do
      context 'when valid nonce arguement is included' do
        context 'when a role_id matching the identity exists' do
          it 'returns the role' do
            identity_and_headers = strategy.callback(
              refresh_token: 'refresh_token',
              nonce: 'nonce'
            )

            expect(identity_and_headers[:identity]).to eq('alice')
            expect(identity_and_headers[:headers]).to include(
              'X-OIDC-Refresh-Token' => refresh_token
            )
          end
        end
      end

      context 'when required parameters are missing' do
        context 'when nonce is missing' do
          it 'raises a `MissingRequestParam` error' do
            expect { strategy.callback(refresh_token: 'refresh_token') }
              .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
          end
        end
      end
    end
  end
end
