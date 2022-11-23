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

  let(:id_token_class) do
    ::OpenIDConnect::ResponseObject::IdToken
  end

  let(:client) do
    VCR.use_cassette("authenticators/authn-oidc/v2/client_load") do
      client = Authentication::AuthnOidc::V2::Client.new(
        authenticator: authenticator,
        oidc_id_token: id_token_class
      )
      # The call `oidc_client` queries the OIDC endpoint. As such,
      # we need to wrap this in a VCR call. Calling this before
      # returning the client to allow this call to be more effectively
      # mocked.
      client.oidc_client
      client
    end
  end

  describe '.get_bearer_token' do
    context 'when authorization code provided' do
      context 'when code is valid', vcr: 'authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials' do
        it 'returns a valid bearer token' do
          # Because JWT tokens have an expiration timeframe, we need to hold time
          # constant after caching the request.
          travel_to(Time.parse("2022-09-30 17:02:17 +0000")) do
            bearer_token = client.get_bearer_token(
              code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
              code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
            )

            expect(bearer_token).to be_a_kind_of(OpenIDConnect::AccessToken)
          end
        end
      end

      context 'when code_verifier is invalid', vcr: 'authenticators/authn-oidc/v2/client_callback-invalid_code_verifier' do
        it 'raises an error' do
          travel_to(Time.parse("2022-10-17 17:23:30 +0000")) do
            expect do
              client.get_bearer_token(
                code: 'GV48_SF4a19ghvBhVbbSG3Lr8BuFl8PhWVPZSbokV2o',
                code_verifier: 'bad-code-verifier'
              )
            end.to raise_error(
              Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
              "CONJ00133E Access Token retrieval failure: 'PKCE verification failed'"
            )
          end
        end
      end

      context 'when code is invalid or expired', vcr: 'authenticators/authn-oidc/v2/client_callback-expired_code-valid_oidc_credentials' do
        it 'raises an error' do
          expect do
            client.get_bearer_token(
              code: 'SNSPeiQJ0-D6nUHTg-Ht9ZoDxIaaWBB80pnYuXY2VxU',
              code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d'
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
            "CONJ00133E Access Token retrieval failure: 'Authorization code is invalid or has expired'"
          )
        end
      end
    end

    context 'when refresh token provided' do
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

      context 'when refresh token is valid', vcr: 'authenticators/authn-oidc/v2/client_refresh-valid_token_with_rotation' do
        it 'returns a valid bearer token' do
          travel_to(Time.parse("2022-10-19 17:02:17 +0000")) do
            bearer_token = client.get_bearer_token(
              refresh_token: 'a8VLPRtcOS5-IFYXkZYzZbrIhSJq6trFXxYJyKbaUng'
            )

            expect(bearer_token).to be_a_kind_of(OpenIDConnect::AccessToken)
          end
        end
      end

      context 'when refresh token is invalid or expired', vcr: 'authenticators/authn-oidc/v2/client_refresh-invalid_token' do
        it 'raises an error' do
          travel_to(Time.parse("2022-10-19 17:02:17 +0000")) do
            expect do
              client.get_bearer_token(
                refresh_token: 'a8VLPRtcOS5-IFYXkZYzZbrIhSJq6trFXxYJyKbaUng'
              )
            end.to raise_error(
              Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
              "CONJ00133E Access Token retrieval failure: 'Refresh token is invalid or has expired'"
            )
          end
        end
      end
    end
  end

  describe '.extract_identity_and_refresh_tokens', vcr: 'empty' do
    let(:refresh_token)        { 'sample_refresh_token' }
    let(:nonce)                { 'sample_nonce' }
    let(:grant)                { 'sample_grant' }

    let(:id_token)             { 'id_token' }
    let(:decoded_id_token)     { 'sample_decoded_id_token' }

    let(:access_token)         { 'access_token' }
    let(:decoded_access_token) { 'sample_decoded_access_token' }

    let(:bearer_token) {
      instance_double(OpenIDConnect::AccessToken).tap do |double|
        allow(double).to receive(:raw_attributes).and_return(
          { 'grant' => grant }
        )
        allow(double).to receive(:id_token).and_return(id_token)
        allow(double).to receive(:access_token).and_return(access_token)
        allow(double).to receive(:refresh_token).and_return(refresh_token)
      end
    }

    context 'if the provided bearer token includes an identity token' do
      it 'returns the embedded identity and refresh tokens' do
        allow(client).to receive(:decode_identity_token)
          .with(id_token: id_token)
          .and_return(decoded_id_token)
        allow(client).to receive(:verify_identity_token)
          .with(decoded_id_token: decoded_id_token, nonce: nonce)
          .and_return(true)

        response = client.extract_identity_and_refresh_tokens(
          bearer_token: bearer_token
        )

        expect(response).to eq({
          id_token: decoded_id_token,
          raw_id_token: id_token,
          refresh_token: refresh_token
        })
      end
    end

    context 'if the provided bearer token does not include an identity token' do
      it 'returns the embedded access and refresh tokens' do
        allow(client).to receive(:decode_identity_token)
          .with(id_token: access_token)
          .and_return(decoded_access_token)
        allow(client).to receive(:verify_identity_token)
          .with(decoded_id_token: decoded_access_token, nonce: nonce)
          .and_return(true)
        allow(bearer_token).to receive(:id_token).and_return(nil)

        response = client.extract_identity_and_refresh_tokens(
          bearer_token: bearer_token
        )

        expect(response).to eq({
          id_token: decoded_access_token,
          raw_id_token: access_token,
          refresh_token: refresh_token
        })
      end
    end
  end

  describe '.decode_identity_token', vcr: 'empty' do
    let(:id_token_claims) {
      {
        iss: 'https://dev-92899796.okta.com/oauth2/default',
        aud: '0oa3w3xig6rHiu9yT5d7',
        sub: 'alice',
        iat: Time.now,
        exp: Time.now + 600
      }
    }

    let(:decoded_id_token) {
      OpenIDConnect::ResponseObject::IdToken.new id_token_claims
    }

    let(:id_token_class) {
      class_double(OpenIDConnect::ResponseObject::IdToken).tap do |double|
        allow(double).to receive(:decode).and_return(decoded_id_token)
      end
    }

    let(:discovery_information) {
      instance_double(OpenIDConnect::Discovery::Provider::Config::Response).tap do |double|
        allow(double).to receive(:jwks).and_return('jwks_details')
      end
    }

    def mock_oidc_discovery
      allow(client).to receive(:discovery_information)
        .and_return(discovery_information)
    end

    context 'when given some encoded identity token object' do
      it 'returns a decoded identity token' do
        mock_oidc_discovery
        response = client.decode_identity_token(id_token: 'encoded_id_token')
        expect(response).to eq(decoded_id_token)
      end
    end
  end

  describe '.verify_identity_token', vcr: 'empty' do
    let(:id_token_claims) {
      {
        iss: 'https://dev-92899796.okta.com/oauth2/default',
        aud: '0oa3w3xig6rHiu9yT5d7',
        sub: 'alice',
        iat: Time.now,
        exp: Time.now + 600
      }
    }

    let(:nonce) { 'some-nonce' }
    let(:expected_nonce) { nonce }

    def run_verify
      client.verify_identity_token(
        decoded_id_token: decoded_id_token,
        nonce: expected_nonce,
        refresh: refresh
      )
    end

    context 'when given a valid identity token' do
      context 'when using a refresh_token grant type' do
        let(:refresh) { true }

        context 'when the identity token does not contain a nonce value' do
          let(:decoded_id_token) {
            OpenIDConnect::ResponseObject::IdToken.new id_token_claims.merge(nonce: nil)
          }

          it 'is verified' do
            response = run_verify
            expect(response).to eq(true)
          end
        end

        context 'when the identity token contains a nonce value' do
          let(:decoded_id_token) {
            OpenIDConnect::ResponseObject::IdToken.new id_token_claims.merge(nonce: nonce)
          }

          context 'when the expected nonce matches' do
            it 'is verified' do
              response = run_verify
              expect(response).to eq(true)
            end
          end

          context 'when the expected nonce does not match' do
            let(:expected_nonce) { 'bad-nonce' }

            it 'raises an error' do
              expect { run_verify }.to raise_error(
                Errors::Authentication::AuthnOidc::TokenVerificationFailed,
                "CONJ00128E JWT Token validation failed: 'Provided nonce does not match the nonce in the JWT'"
              )
            end
          end
        end
      end

      context 'when using an authorization code grant type' do
        let(:refresh) { false }

        let(:decoded_id_token) {
          OpenIDConnect::ResponseObject::IdToken.new id_token_claims.merge(nonce: nonce)
        }

        context 'when the expected nonce matches' do
          it 'is verified' do
            response = run_verify
            expect(response).to eq(true)
          end
        end

        context 'when the expected nonce does not match' do
          let(:expected_nonce) { 'bad-nonce' }

          it 'raises an error' do
            expect { run_verify }.to raise_error(
              Errors::Authentication::AuthnOidc::TokenVerificationFailed,
              "CONJ00128E JWT Token validation failed: 'Provided nonce does not match the nonce in the JWT'"
            )
          end
        end
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

  describe '.logout', vcr: 'authenticators/authn-oidc/v2/logout-valid_refresh_token' do
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

    context 'when passed a valid refresh_token, nonce and state values' do
      context 'when passed post_logout_redirect_uri value' do
        it 'returns a properly formatted logout uri and identity token' do
          # Because JWT tokens have an expiration timeframe, we need to hold time
          # constant after caching the request.
          travel_to(Time.parse("2022-11-21 17:02:17 +0000")) do
            expect(client.oidc_client).to receive(:revoke!).twice

            logout_uri = client.exchange_refresh_token_for_logout_uri(
              refresh_token: 'WjL3C_CGeYIVnV4WfcjyNI6uJRn0wwjIqpsJ_yeHSvo',
              nonce: 'some-nonce',
              state: 'some-state',
              post_logout_redirect_uri: 'https://conjur.org/redirect'
            )

            expect(logout_uri).to be_a_kind_of(URI::HTTPS)
            expect(logout_uri.query).to include('state=some-state')
            expect(logout_uri.query).to include('post_logout_redirect_uri=https%3A%2F%2Fconjur.org%2Fredirect')
          end
        end

        context 'when psot_logout_redirect_uri value omitted' do
          it 'returns a properly formatted logout uri and identity token' do
            # Because JWT tokens have an expiration timeframe, we need to hold time
            # constant after caching the request.
            travel_to(Time.parse("2022-11-21 17:02:17 +0000")) do
              expect(client.oidc_client).to receive(:revoke!).twice

              logout_uri = client.exchange_refresh_token_for_logout_uri(
                refresh_token: 'WjL3C_CGeYIVnV4WfcjyNI6uJRn0wwjIqpsJ_yeHSvo',
                nonce: 'some-nonce',
                state: 'some-state',
                post_logout_redirect_uri: nil
              )

              expect(logout_uri).to be_a_kind_of(URI::HTTPS)
              expect(logout_uri.query).to include('state=some-state')
              expect(logout_uri.query).not_to include('post_logout_redirect_uri')
            end
          end
        end
      end
    end
  end
end
