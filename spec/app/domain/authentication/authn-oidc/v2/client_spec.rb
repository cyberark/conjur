# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::Client) do
  let(:authenticator) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
      provider_uri: 'https://dev-92899796.okta.com/oauth2/default',
      redirect_uri: 'http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate',
      client_id: '0oa3w3xig6rHiu9yT5d7',
      client_secret: 'e349BMTTIpLO-rPuPqLLkLyH_pO-loUzhIVJCrHj',
      claim_mapping: 'foo',
      account: 'bar',
      service_id: 'baz'
    )
  end

  let(:client) do
    Authentication::AuthnOidc::V2::Client.new(
      authenticator: authenticator
    )
  end

  describe '.callback' do
    context 'when credentials are valid' do
      it 'returns a valid JWT token', vcr: 'authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials' do
        # Because JWT tokens have an expiration timeframe, we need to hold
        # time constant after caching the request.
        travel_to(Time.parse("2022-09-30 17:02:17 +0000")) do
          token = client.callback(
            code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
            code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
            nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
          )
          expect(token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
          expect(token.raw_attributes['nonce']).to eq('7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d')
          expect(token.raw_attributes['preferred_username']).to eq('test.user3@mycompany.com')
          expect(token.aud).to eq('0oa3w3xig6rHiu9yT5d7')
        end
      end
    end

    context 'when JWT has expired' do
      it 'raises an error', vcr: 'authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials' do
        travel_to(Time.parse("2022-10-01 17:02:17 +0000")) do
          expect do
            client.callback(
              code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
              code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
              nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
            )
          end.to raise_error(
            OpenIDConnect::ResponseObject::IdToken::ExpiredToken,
            'Invalid ID token: Expired token'
          )
        end
      end
    end

    context 'when code has previously been used' do
      it 'raise an exception', vcr: 'authenticators/authn-oidc/v2/client_callback-used_code-valid_oidc_credentials' do
        expect do
          client.callback(
            code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
            code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
            nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
          )
        end.to raise_error(
          Rack::OAuth2::Client::Error,
          'invalid_grant :: The authorization code is invalid or has expired.'
        )
      end
    end

    context 'when code has expired', vcr: 'authenticators/authn-oidc/v2/client_callback-expired_code-valid_oidc_credentials' do
      it 'raise an exception' do
        expect do
          client.callback(
            code: 'SNSPeiQJ0-D6nUHTg-Ht9ZoDxIaaWBB80pnYuXY2VxU',
            code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
            nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
          )
        end.to raise_error(
          Rack::OAuth2::Client::Error,
          'invalid_grant :: The authorization code is invalid or has expired.'
        )
      end
    end
  end

  describe '.oidc_client' do
    context 'when credentials are valid' do
      it 'returns a valid oidc client' do
        oidc_client = client.oidc_client

        expect(oidc_client).to be_a_kind_of(OpenIDConnect::Client)
        expect(oidc_client.identifier).to eq('0oa3w3xig6rHiu9yT5d7')
        expect(oidc_client.secret).to eq('e349BMTTIpLO-rPuPqLLkLyH_pO-loUzhIVJCrHj')
        expect(oidc_client.redirect_uri).to eq('http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate')
        expect(oidc_client.scheme).to eq('https')
        expect(oidc_client.host).to eq('dev-92899796.okta.com')
        expect(oidc_client.port).to eq(443)
        expect(oidc_client.authorization_endpoint).to eq('/oauth2/default/v1/authorize')
        expect(oidc_client.token_endpoint).to eq('/oauth2/default/v1/token')
        expect(oidc_client.userinfo_endpoint).to eq('/oauth2/default/v1/userinfo')
      end
    end
  end

  describe '.discovery_information', vcr: 'authenticators/authn-oidc/v2/discovery_endpoint-valid_oidc_credentials' do
    context 'when credentials are valid' do
      it 'endpoint returns valid data' do
        discovery_information = client.discovery_information(invalidate: true)

        expect(discovery_information.authorization_endpoint).to eq(
          'https://dev-92899796.okta.com/oauth2/default/v1/authorize'
        )
        expect(discovery_information.token_endpoint).to eq(
          'https://dev-92899796.okta.com/oauth2/default/v1/token'
        )
        expect(discovery_information.userinfo_endpoint).to eq(
          'https://dev-92899796.okta.com/oauth2/default/v1/userinfo'
        )
        expect(discovery_information.jwks_uri).to eq(
          'https://dev-92899796.okta.com/oauth2/default/v1/keys'
        )
        expect(discovery_information.end_session_endpoint).to eq(
          'https://dev-92899796.okta.com/oauth2/default/v1/logout'
        )
      end
    end

    context 'when provider URI is invalid', vcr: 'authenticators/authn-oidc/v2/discovery_endpoint-invalid_oidc_provider' do
      it 'returns an timeout error' do
        client = Authentication::AuthnOidc::V2::Client.new(
          authenticator: Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
            provider_uri: 'https://foo.bar1234321.com',
            redirect_uri: 'http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate',
            client_id: '0oa3w3xig6rHiu9yT5d7',
            client_secret: 'e349BMTTIpLO-rPuPqLLkLyH_pO-loUzhIVJCrHj',
            claim_mapping: 'foo',
            account: 'bar',
            service_id: 'baz'
          )
        )

        expect{client.discovery_information(invalidate: true)}.to raise_error(
          Errors::Authentication::OAuth::ProviderDiscoveryFailed
        )
      end
    end
  end
end
