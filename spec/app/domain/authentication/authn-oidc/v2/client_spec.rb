# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::Client) do
  def client(config)
    VCR.use_cassette("authenticators/authn-oidc/v2/#{config[:service_id]}/client_load") do
      client = Authentication::AuthnOidc::V2::Client.new(
        authenticator: Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
          provider_uri: config[:provider_uri],
          redirect_uri: "http://localhost:3000/authn-oidc/#{config[:service_id]}/cucumber/authenticate",
          client_id: config[:client_id],
          client_secret: config[:client_secret],
          claim_mapping: "email",
          account: "bar",
          service_id: "baz"
        )
      )
      # The call `oidc_client` queries the OIDC endpoint. As such,
      # we need to wrap this in a VCR call. Calling this before
      # returning the client to allow this call to be more effectively
      # mocked.
      client.oidc_client
      client
    end
  end

  shared_examples 'happy path' do |config|
    describe '.callback', type: 'unit' do
      context 'when credentials are valid' do
        it 'returns a valid JWT token', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-valid_oidc_credentials" do
          travel_to(Time.parse(config[:auth_time])) do
            token = client(config).callback(
              code: config[:code],
              code_verifier: config[:code_verifier],
              nonce: config[:nonce]
            )
            expect(token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
            expect(token.raw_attributes['nonce']).to eq(config[:nonce])
            expect(token.raw_attributes['preferred_username']).to eq(config[:username])
            expect(token.aud).to eq(config[:client_id])
          end
        end
      end
    end
  end

  shared_examples 'token retrieval failures' do |config|
    describe '.callback', type: 'unit' do
      context 'when code verifier does not match' do
        it 'raises an error', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-invalid_code_verifier" do
          travel_to(Time.parse(config[:auth_time])) do
            expect do
              client(config).callback(
                code: config[:code],
                code_verifier: 'bad-code-verifier',
                nonce: config[:nonce]
              )
            end.to raise_error(
              Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
              "CONJ00133E Access Token retrieval failure: 'PKCE verification failed'"
            )
          end
        end
      end

      context 'when code has previously been used' do
        it 'raise an exception', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-used_code-valid_oidc_credentials" do
          expect do
            client(config).callback(
              code: config[:code],
              code_verifier: config[:code_verifier],
              nonce: config[:nonce]
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
            "CONJ00133E Access Token retrieval failure: 'Authorization code is invalid or has expired'"
          )
        end
      end
  
      context 'when code has expired', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-expired_code-valid_oidc_credentials" do
        it 'raise an exception' do
          expect do
            client(config).callback(
              code: config[:code],
              code_verifier: config[:code_verifier],
              nonce: config[:nonce]
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
            "CONJ00133E Access Token retrieval failure: 'Authorization code is invalid or has expired'"
          )
        end
      end
    end
  end

  shared_examples 'token validation failures' do |config|
    describe '.callback', type: 'unit' do
      context 'when nonce does not match' do
        it 'raises an error', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-valid_oidc_credentials" do
          travel_to(Time.parse(config[:auth_time])) do
            expect do
              client(config).callback(
                code: config[:code],
                code_verifier: config[:code_verifier],
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
        it 'raises an error', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-valid_oidc_credentials" do
          travel_to(Time.parse(config[:auth_time]) + 86400) do
            expect do
              client(config).callback(
                code: config[:code],
                code_verifier: config[:code_verifier],
                nonce: config[:nonce]
              )
            end.to raise_error(
              Errors::Authentication::AuthnOidc::TokenVerificationFailed,
              "CONJ00128E JWT Token validation failed: 'JWT has expired'"
            )
          end
        end
      end
    end
  end

  shared_examples 'client setup' do |config|
    describe '.oidc_client', type: 'unit' do
      context 'when credentials are valid' do
        it 'returns a valid oidc client', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_initialization" do
          oidc_client = client(config).oidc_client

          expect(oidc_client).to be_a_kind_of(OpenIDConnect::Client)
          expect(oidc_client.identifier).to eq(config[:client_id])
          expect(oidc_client.secret).to eq(config[:client_secret])
          expect(oidc_client.redirect_uri).to eq("http://localhost:3000/authn-oidc/#{config[:service_id]}/cucumber/authenticate")
          expect(oidc_client.scheme).to eq('https')
          expect(oidc_client.host).to eq(config[:host])
          expect(oidc_client.port).to eq(443)
          expect(oidc_client.authorization_endpoint).to eq(config[:expected_authz])
          expect(oidc_client.token_endpoint).to eq(config[:expected_token])
          expect(oidc_client.userinfo_endpoint).to eq(config[:expected_userinfo])
        end
      end
    end

    describe '.discovery_information', type: 'unit', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/discovery_endpoint-valid_oidc_credentials" do
      context 'when credentials are valid' do
        it 'endpoint returns valid data' do
          discovery_information = client(config).discovery_information(invalidate: true)

          expect(discovery_information.authorization_endpoint).to eq("https://#{config[:host]}#{config[:expected_authz]}")
          expect(discovery_information.token_endpoint).to eq("https://#{config[:host]}#{config[:expected_token]}")
          expect(discovery_information.userinfo_endpoint).to eq("https://#{config[:host]}#{config[:expected_userinfo]}")
          expect(discovery_information.jwks_uri).to eq("https://#{config[:host]}#{config[:expected_keys]}")
        end
      end

      context 'when provider URI is invalid', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/discovery_endpoint-invalid_oidc_provider" do
        it 'returns an timeout error' do
          client = Authentication::AuthnOidc::V2::Client.new(
            authenticator: Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
              provider_uri: 'https://foo.bar1234321.com',
              redirect_uri: "http://localhost:3000/authn-oidc/#{config[:service_id]}/cucumber/authenticate",
              client_id: config[:client_id],
              client_secret: config[:client_secret],
              claim_mapping: config[:claim_mapping],
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

  describe 'OIDC client targeting Okta' do
    config = {
      provider_uri: 'https://dev-92899796.okta.com/oauth2/default',
      host: 'dev-92899796.okta.com',
      client_id: '0oa3w3xig6rHiu9yT5d7',
      client_secret: 'e349BMTTIpLO-rPuPqLLkLyH_pO-loUzhIVJCrHj',
      service_id: 'okta-2',
      expected_authz: '/oauth2/default/v1/authorize',
      expected_token: '/oauth2/default/v1/token',
      expected_userinfo: '/oauth2/default/v1/userinfo',
      expected_keys: '/oauth2/default/v1/keys',
      auth_time: '2022-09-30 17:02:17 +0000',
      code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
      code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
      nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d',
      username: 'test.user3@mycompany.com'
    }

    include_examples 'client setup', config
    include_examples 'happy path', config
    include_examples 'token retrieval failures', config
    include_examples 'token validation failures', config
  end

  describe 'OIDC client targeting Identity' do
    config = {
      provider_uri: 'https://redacted-host/redacted_app/',
      host: 'redacted-host',
      client_id: 'redacted-id',
      client_secret: 'redacted-secret',
      service_id: 'identity',
      expected_authz: '/OAuth2/Authorize/redacted_app',
      expected_token: '/OAuth2/Token/redacted_app',
      expected_userinfo: '/OAuth2/UserInfo/redacted_app',
      expected_keys: '/OAuth2/Keys/redacted_app',
      auth_time: '2023-4-10 18:00:00 +0000',
      code: 'puPaKJOr_E25STHsM_-rOo3fgJBz2TKVNsi8GzBvwS41',
      code_verifier: '9625bb8881c08de323bb17242d6b3552e50aec0e999e15c66a',
      nonce: 'f1daadf8108eaf6ccf3295fd679acc5218f776d1aaaa3d270a'
    }

    include_examples 'client setup', config
    include_examples 'token retrieval failures', config
  end
end
