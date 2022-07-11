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
      nonce: '1656b4264b60af659fce',
      state: 'state',
      account: 'bar',
      service_id: 'baz'
    )
  end

  let(:client) do
    VCR.use_cassette('authenticators/authn-oidc/v2/client') do
      Authentication::AuthnOidc::V2::Client.new(
        authenticator: authenticator
      )
    end
  end

  describe '.callback' do
    context 'when credentials are valid' do
      it 'returns a valid JWT token' do
        # Because JWT tokens have an expiration timeframe, we need to hold
        # time constant after caching the request.
        travel_to(Time.parse("2022-06-30 16:42:17 +0000")) do
          token = VCR.use_cassette('authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials') do
            client.callback(
              code: 'qdDm7On1dEEzNmMlk2bF7IcOF8gCgfvgMCMXXXDlYEE'
            )
          end
          expect(token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
          expect(token.raw_attributes['nonce']).to eq('1656b4264b60af659fce')
          expect(token.raw_attributes['preferred_username']).to eq('test.user3@mycompany.com')
          expect(token.aud).to eq('0oa3w3xig6rHiu9yT5d7')
        end
      end
    end

    context 'when JWT has expired' do
      it 'raises an error' do
        travel_to(Time.parse("2022-06-30 20:42:17 +0000")) do
          VCR.use_cassette('authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials') do
            expect do
              client.callback(
                code: 'qdDm7On1dEEzNmMlk2bF7IcOF8gCgfvgMCMXXXDlYEE'
              )
            end.to raise_error(
              OpenIDConnect::ResponseObject::IdToken::ExpiredToken,
              'Invalid ID token: Expired token'
            )
          end
        end
      end
    end

    context 'when code has previously been used' do
      it 'raise an exception' do
        VCR.use_cassette('authenticators/authn-oidc/v2/client_callback-used_code-valid_oidc_credentials') do
          expect do
            client.callback(
              code: '7wKEGhsN9UEL5MG9EfDJ8KWMToKINzvV29uyPsQZYpo'
            )
          end.to raise_error(
            Rack::OAuth2::Client::Error,
            'invalid_grant :: The authorization code is invalid or has expired.'
          )
        end
      end
    end

    context 'when code has expired' do
      it 'raise an exception' do
        VCR.use_cassette('authenticators/authn-oidc/v2/client_callback-expired_code-valid_oidc_credentials') do
          expect do
            client.callback(
              code: 'SNSPeiQJ0-D6nUHTg-Ht9ZoDxIaaWBB80pnYuXY2VxU'
            )
          end.to raise_error(
            Rack::OAuth2::Client::Error,
            'invalid_grant :: The authorization code is invalid or has expired.'
          )
        end
      end
    end

    context 'when code is invalid' do
      context 'raise an error when' do
        it 'code is nil' do
          expect { client.callback(code: nil) }.to raise_error(
            Errors::Authentication::RequestBody::MissingRequestParam,
            "CONJ00009E Field 'code' is missing or empty in request body"
          )
        end
        it 'code is an empty string' do
          expect { client.callback(code: '') }.to raise_error(
            Errors::Authentication::RequestBody::MissingRequestParam,
            "CONJ00009E Field 'code' is missing or empty in request body"
          )
        end
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

  describe '.discovery_information' do
    context 'when credentials are valid' do
      it 'endpoint returns valid data' do
        discovery_information = VCR.use_cassette('authenticators/authn-oidc/v2/discovery_endpoint-valid_oidc_credentials') do
          client.discovery_information(invalidate: true)
        end

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

    context 'when provider URI is invalid' do
      it 'returns an timeout error' do
        client = Authentication::AuthnOidc::V2::Client.new(
          authenticator: Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
            provider_uri: 'https://foo.bar1234321.com',
            redirect_uri: 'http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate',
            client_id: '0oa3w3xig6rHiu9yT5d7',
            client_secret: 'e349BMTTIpLO-rPuPqLLkLyH_pO-loUzhIVJCrHj',
            claim_mapping: 'foo',
            nonce: '1656b4264b60af659fce',
            state: 'state',
            account: 'bar',
            service_id: 'baz'
          )
        )

        VCR.use_cassette('authenticators/authn-oidc/v2/discovery_endpoint-invalid_oidc_provider') do
          expect{client.discovery_information(invalidate: true)}.to raise_error(
            Errors::Authentication::OAuth::ProviderDiscoveryFailed
          )
        end
      end
    end
  end
end
