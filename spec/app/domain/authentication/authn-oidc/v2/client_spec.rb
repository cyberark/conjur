# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::Client) do
  let(:authn_config) do
    {
      :provider_uri => 'https://dev-92899796.okta.com/oauth2/default',
      :redirect_uri => 'http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate',
      :client_id => '0oa3w3xig6rHiu9yT5d7',
      :client_secret => 'e349BMTTIpLO-rPuPqLLkLyH_pO-loUzhIVJCrHj',
      :claim_mapping => 'foo',
      :account => 'bar',
      :service_id => 'baz'
    }
  end

  let(:authenticator) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
      **authn_config
    )
  end

  let(:client) do
    VCR.use_cassette("authenticators/authn-oidc/v2/client_load") do
      client = Authentication::AuthnOidc::V2::Client.new(
        authenticator: authenticator
      )
      # The call `oidc_client` queries the OIDC endpoint. As such,
      # we need to wrap this in a VCR call. Calling this before
      # returning the client to allow this call to be more effectively
      # mocked.
      client.oidc_client
      client
    end
  end

  describe '.get_token_with_code' do
    context 'when credentials are valid' do
      it 'returns a valid JWT token', vcr: 'authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials' do
        # Because JWT tokens have an expiration timeframe, we need to hold
        # time constant after caching the request.
        travel_to(Time.parse("2022-09-30 17:02:17 +0000")) do
          id_token, refresh_token = client.get_token_with_code(
            code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
            code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
            nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
          )
          expect(id_token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
          expect(id_token.raw_attributes['nonce']).to eq('7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d')
          expect(id_token.raw_attributes['preferred_username']).to eq('test.user3@mycompany.com')
          expect(id_token.aud).to eq('0oa3w3xig6rHiu9yT5d7')

          expect(refresh_token).to be_nil
        end
      end
    end

    context 'when code verifier does not match' do
      it 'raises an error', vcr: 'authenticators/authn-oidc/v2/client_callback-invalid_code_verifier' do
        travel_to(Time.parse("2022-10-17 17:23:30 +0000")) do
          expect do
            client.get_token_with_code(
              code: 'GV48_SF4a19ghvBhVbbSG3Lr8BuFl8PhWVPZSbokV2o',
              code_verifier: 'bad-code-verifier',
              nonce: '3e6bd5235e4692b37ca1f04cb01b6e0cb177aa20dcef19e89f'
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
            "CONJ00133E Access Token retrieval failure: 'PKCE verification failed'"
          )
        end
      end
    end

    context 'when nonce does not match' do
      it 'raises an error', vcr: 'authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials' do
        travel_to(Time.parse("2022-09-30 17:02:17 +0000")) do
          expect do
            client.get_token_with_code(
              code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
              code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
              nonce: 'bad-nonce'
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenVerificationFailed,
            "CONJ00128E JWT Token validation failed: 'Provided nonce does not match the nonce in the JWT'"
          )
        end
      end
    end

    context 'when JWT has expired' do
      it 'raises an error', vcr: 'authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials' do
        travel_to(Time.parse("2022-10-01 17:02:17 +0000")) do
          expect do
            client.get_token_with_code(
              code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
              code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
              nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenVerificationFailed,
            "CONJ00128E JWT Token validation failed: 'JWT has expired'"
          )
        end
      end
    end

    context 'when code has previously been used' do
      it 'raise an exception', vcr: 'authenticators/authn-oidc/v2/client_callback-used_code-valid_oidc_credentials' do
        expect do
          client.get_token_with_code(
            code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
            code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
            nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
          )
        end.to raise_error(
          Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
          "CONJ00133E Access Token retrieval failure: 'Authorization code is invalid or has expired'"
        )
      end
    end

    context 'when code has expired', vcr: 'authenticators/authn-oidc/v2/client_callback-expired_code-valid_oidc_credentials' do
      it 'raise an exception' do
        expect do
          client.get_token_with_code(
            code: 'SNSPeiQJ0-D6nUHTg-Ht9ZoDxIaaWBB80pnYuXY2VxU',
            code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
            nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
          )
        end.to raise_error(
          Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
          "CONJ00133E Access Token retrieval failure: 'Authorization code is invalid or has expired'"
        )
      end
    end

    context 'when refresh token flow is enabled' do
      # The 'offline_access' scope enables Okta's refresh token flow
      let(:authenticator) do
        Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
          **authn_config.merge!({ :provider_scope => 'offline_access' })
        )
      end

      context 'when credentials are valid' do
        it 'returns valid ID and refresh tokens', vcr: 'authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials_and_refresh' do
          # Because JWT tokens have an expiration timeframe, we need to hold
          # time constant after caching the request.
          travel_to(Time.parse("2022-09-30 17:02:17 +0000")) do
            id_token, refresh_token = client.get_token_with_code(
              code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
              code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
              nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
            )
            expect(id_token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
            expect(id_token.raw_attributes['nonce']).to eq('7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d')
            expect(id_token.raw_attributes['preferred_username']).to eq('test.user3@mycompany.com')
            expect(id_token.aud).to eq('0oa3w3xig6rHiu9yT5d7')

            expect(refresh_token).not_to be_nil
            expect(refresh_token).to be_a_kind_of(String)
            expect(refresh_token).to eq('kXMJFtgtaEpOGn0Zk2x15i8umXIWp4aqY1Mh7zscfGI')
          end
        end
      end
    end
  end

  describe '.get_token_with_refresh_token' do
    # Use different Okta authorization server with refresh tokens enabled.
    # At some point, all these test cases should point to a single Okta server,
    # with PKCE and refresh tokens both enabled.
    let(:authenticator) do
      Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
        **authn_config.merge!({
          :provider_uri => 'https://dev-56357110.okta.com/oauth2/default',
          :client_id => '0oa6ccivzf3nEeiGt5d7',
          :client_secret => 'YnAukUECEAtsWSWCHPzi1coiZZeOhdvQOSnri4Kz',
          :provider_scope => 'offline_access'
        })
      )
    end

    context 'when refresh token is valid' do
      context 'with refresh token rotation disabled' do
        it 'returns a valid JWT token', vcr: 'authenticators/authn-oidc/v2/client_refresh-valid_token' do
          travel_to(Time.parse("2022-10-19 17:02:17 +0000")) do
            allow(client).to receive(:revoke).and_return(:success)

            id_token, refresh_token = client.get_token_with_refresh_token(
              refresh_token: 'a8VLPRtcOS5-IFYXkZYzZbrIhSJq6trFXxYJyKbaUng',
              nonce: 'some-nonce'
            )

            expect(id_token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
            expect(id_token.raw_attributes['nonce']).to be_nil
            expect(id_token.raw_attributes['preferred_username']).to eq('test.user3@mycompany.com')
            expect(id_token.aud).to eq('0oa6ccivzf3nEeiGt5d7')

            expect(refresh_token).to be_nil
          end
        end
      end

      context 'with refresh token rotation enabled' do
        it 'returns a valid JWT token and refresh token', vcr: 'authenticators/authn-oidc/v2/client_refresh-valid_token_with_rotation' do
          travel_to(Time.parse("2022-10-19 17:02:17 +0000")) do
            allow(client).to receive(:revoke).and_return(:success)

            id_token, refresh_token = client.get_token_with_refresh_token(
              refresh_token: 'a8VLPRtcOS5-IFYXkZYzZbrIhSJq6trFXxYJyKbaUng',
              nonce: 'some-nonce'
            )

            expect(id_token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
            expect(id_token.raw_attributes['nonce']).to be_nil
            expect(id_token.raw_attributes['preferred_username']).to eq('test.user3@mycompany.com')
            expect(id_token.aud).to eq('0oa6ccivzf3nEeiGt5d7')

            expect(refresh_token).to eq('dyJXfWUg1Xjt4KP7IQ7qcHUVNtKNWmmtOu9qNScjkN8')
          end
        end
      end
    end

    context 'when refresh token is invalid or expired' do
      it 'raises an error', vcr: 'authenticators/authn-oidc/v2/client_refresh-invalid_token' do
        travel_to(Time.parse("2022-10-19 17:02:17 +0000")) do
          expect do
            client.get_token_with_refresh_token(
              refresh_token: 'a8VLPRtcOS5-IFYXkZYzZbrIhSJq6trFXxYJyKbaUng',
              nonce: 'some-nonce'
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
            "CONJ00133E Access Token retrieval failure: 'Refresh token is invalid or has expired'"
          )
        end
      end
    end
  end

  describe '.revoke' do
    let(:authenticator) do
      Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
        **authn_config.merge!({
          :provider_uri => 'https://dev-56357110.okta.com/oauth2/default',
          :client_id => '0oa6ccivzf3nEeiGt5d7',
          :client_secret => 'YnAukUECEAtsWSWCHPzi1coiZZeOhdvQOSnri4Kz',
          :provider_scope => 'offline_access'
        })
      )
    end

    context 'given a valid refresh token', vcr: 'authenticators/authn-oidc/v2/revoke_token-valid_token' do
      let(:revoke) do
        client.revoke('R2sJgxtLGEL-F_-3AnE5XWqmYKTnc3zTsu0P5uddwmE')
      end

      it 'succeeds' do
        expect { revoke }.not_to raise_error
      end

      it 'cannot be used in subsequent requests' do
        expect do
          client.get_token_with_refresh_token(
            refresh_token: 'R2sJgxtLGEL-F_-3AnE5XWqmYKTnc3zTsu0P5uddwmE',
            nonce: 'some-nonce'
          )
        end.to raise_error(
          Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
          "CONJ00133E Access Token retrieval failure: 'Refresh token is invalid or has expired'"
        )
      end
    end

    context 'given an invalid refresh token', vcr: 'authenticators/authn-oidc/v2/revoke_token-invalid_token' do
      let(:revoke) do
        client.revoke('some-refresh-token')
      end

      it 'succeeds' do
        expect {revoke }.not_to raise_error
      end
    end
  end

  describe '.end_session' do
    let(:authenticator) do
      Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
        **authn_config.merge!({
          :provider_uri => 'https://dev-56357110.okta.com/oauth2/default',
          :client_id => '0oa6ccivzf3nEeiGt5d7',
          :client_secret => 'YnAukUECEAtsWSWCHPzi1coiZZeOhdvQOSnri4Kz',
          :provider_scope => 'offline_access'
        })
      )
    end

    context 'ending a user session', vcr: 'empty' do
      let(:end_session) do
        allow(client).to receive(:revoke).and_return(:success)
        allow(client).to receive(:get_token_pair).and_return(['id_token', 'new_refresh_token'])
        allow(client).to receive(:decode_id_token).and_return('decoded_id_token')
        allow(client).to receive(:verify_id_token).and_return(true)

        client.end_session(
          refresh_token: 'old_refresh_token',
          nonce: 'some-nonce',
          state: 'some-state',
          redirect_uri: 'https://conjur.org/redirect?foo=bar'
        )
      end

      it 'returns a properly formatted URI' do
        uri = end_session

        expect(uri).to be_a_kind_of(URI::HTTPS)
        expect(uri.to_s).to eq('https://dev-56357110.okta.com/oauth2/default/v1/logout?id_token_hint=id_token&state=some-state&post_logout_redirect_uri=https%3A%2F%2Fconjur.org%2Fredirect%3Ffoo%3Dbar')
      end

      it 'revokes the remaining refresh tokens' do
        expect(client).to receive(:revoke).with('old_refresh_token')
        expect(client).to receive(:revoke).with('new_refresh_token')

        end_session
      end
    end
  end

  describe '.oidc_client' do
    context 'when credentials are valid' do
      it 'returns a valid oidc client', vcr: 'authenticators/authn-oidc/v2/client_initialization' do
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
