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
    Authentication::AuthnOidc::V2::Client.new(
      authenticator: authenticator
    )
  end

  describe '.validate_code' do
    context 'when credentials are valid' do
      it 'returns a valid JWT token', vcr: 'authenticators/authn-oidc/v2/client_callback-valid_oidc_credentials' do
        # Because JWT tokens have an expiration timeframe, we need to hold
        # time constant after caching the request.
        travel_to(Time.parse("2022-06-30 16:42:17 +0000")) do
          token = client.validate_code(
            code: 'qdDm7On1dEEzNmMlk2bF7IcOF8gCgfvgMCMXXXDlYEE'
          )
          expect(token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
          expect(token.raw_attributes['nonce']).to eq('1656b4264b60af659fce')
          expect(token.raw_attributes['preferred_username']).to eq('test.user3@mycompany.com')
          expect(token.aud).to eq('0oa3w3xig6rHiu9yT5d7')
        end
      end
    end

    context 'when code has previously been used' do
      it 'raise an exception', vcr: 'authenticators/authn-oidc/v2/client_callback-used_code-valid_oidc_credentials' do
        expect do
          client.validate_code(
            code: '7wKEGhsN9UEL5MG9EfDJ8KWMToKINzvV29uyPsQZYpo'
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
          client.validate_code(
            code: 'SNSPeiQJ0-D6nUHTg-Ht9ZoDxIaaWBB80pnYuXY2VxU'
          )
        end.to raise_error(
          Rack::OAuth2::Client::Error,
          'invalid_grant :: The authorization code is invalid or has expired.'
        )
      end
    end

    context 'when code is invalid' do
      context 'raises an error when' do
        it 'code is nil' do
          expect { client.validate_code(code: nil) }.to raise_error(
            Errors::Authentication::RequestBody::MissingRequestParam,
            "CONJ00009E Field 'code' is missing or empty in request body"
          )
        end
        it 'code is an empty string' do
          expect { client.validate_code(code: '') }.to raise_error(
            Errors::Authentication::RequestBody::MissingRequestParam,
            "CONJ00009E Field 'code' is missing or empty in request body"
          )
        end
      end
    end
  end

  describe '.validate_token' do
    context 'when token is valid' do
      it 'returns a valid JWT token', vcr: 'authenticators/authn-oidc/v2/client_callback-validate-token' do
        # Because JWT tokens have an expiration timeframe, we need to hold
        # time constant after caching the request.
        travel_to(Time.parse("2022-06-30 16:42:17 +0000")) do
          token = client.validate_token(
            token: 'eyJraWQiOiJZR1NUUUxBVDdLb1JPd2RhTWtWa1RyNXhIUXM3Zm1jNG5CTUJsT1NuZHVzIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsIm5hbWUiOiJUZXN0IFVzZXIzIiwidmVyIjoxLCJpc3MiOiJodHRwczovL2Rldi05Mjg5OTc5Ni5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6IjBvYTN3M3hpZzZySGl1OXlUNWQ3IiwiaWF0IjoxNjU2NjA3MzgyLCJleHAiOjE2NTY2MTA5ODIsImp0aSI6IklELjdubmF3YUdkc1daT2VKazl6YWxNUFpnVGhuX3Z2QkNDcndBazVHcHRjS00iLCJhbXIiOlsicHdkIl0sImlkcCI6IjAwbzN3MXk4dHV1YVljQ1Q3NWQ3Iiwibm9uY2UiOiIxNjU2YjQyNjRiNjBhZjY1OWZjZSIsInByZWZlcnJlZF91c2VybmFtZSI6InRlc3QudXNlcjNAbXljb21wYW55LmNvbSIsImF1dGhfdGltZSI6MTY1NjYwNjcxNywiYXRfaGFzaCI6IkU3TDJUUEZrM0dGMXlRQzdEaUJ1UkEifQ.YDeYm3bP5hFmP4u6uuKV2fU8ICZ72LIa_tlG0qfYCVcHS1lZeHqbyJPEWfgmnSGAxenieavntCbsW-g6UdtCeGsoXGPw3tDW-oiNyZsdBPw-xTCg01JSd4d26Oponia0amkhvglXRkAuGVRJciO89oTVabxvYlcP-PvOeaiFjn4q9hFvTQTI6sItPhxp6rMa3Ri9VJkOR1fdkI-w9bwGW8WN-u4GscQoCU054HPVaHPT8fQ86Bl3Aty8Bf2e5Gw6WIpLSFgWd6Nmhiv1ANUcW8vSLxsefWI6N37j-0fCa1fgZefv-M-Kg_dfE-8a33YxzAwN5NB3HCbv7FNsYD1rIg'
          )
          expect(token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
          expect(token.raw_attributes['nonce']).to eq('1656b4264b60af659fce')
          expect(token.raw_attributes['preferred_username']).to eq('test.user3@mycompany.com')
          expect(token.aud).to eq('0oa3w3xig6rHiu9yT5d7')
        end
      end
    end

    context 'when token has expired' do
      it 'raises an error', vcr: 'authenticators/authn-oidc/v2/client_callback-validate-token' do
        travel_to(Time.parse("2022-06-30 20:42:17 +0000")) do
          expect do
            client.validate_token(
              token: 'eyJraWQiOiJZR1NUUUxBVDdLb1JPd2RhTWtWa1RyNXhIUXM3Zm1jNG5CTUJsT1NuZHVzIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsIm5hbWUiOiJUZXN0IFVzZXIzIiwidmVyIjoxLCJpc3MiOiJodHRwczovL2Rldi05Mjg5OTc5Ni5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6IjBvYTN3M3hpZzZySGl1OXlUNWQ3IiwiaWF0IjoxNjU2NjA3MzgyLCJleHAiOjE2NTY2MTA5ODIsImp0aSI6IklELjdubmF3YUdkc1daT2VKazl6YWxNUFpnVGhuX3Z2QkNDcndBazVHcHRjS00iLCJhbXIiOlsicHdkIl0sImlkcCI6IjAwbzN3MXk4dHV1YVljQ1Q3NWQ3Iiwibm9uY2UiOiIxNjU2YjQyNjRiNjBhZjY1OWZjZSIsInByZWZlcnJlZF91c2VybmFtZSI6InRlc3QudXNlcjNAbXljb21wYW55LmNvbSIsImF1dGhfdGltZSI6MTY1NjYwNjcxNywiYXRfaGFzaCI6IkU3TDJUUEZrM0dGMXlRQzdEaUJ1UkEifQ.YDeYm3bP5hFmP4u6uuKV2fU8ICZ72LIa_tlG0qfYCVcHS1lZeHqbyJPEWfgmnSGAxenieavntCbsW-g6UdtCeGsoXGPw3tDW-oiNyZsdBPw-xTCg01JSd4d26Oponia0amkhvglXRkAuGVRJciO89oTVabxvYlcP-PvOeaiFjn4q9hFvTQTI6sItPhxp6rMa3Ri9VJkOR1fdkI-w9bwGW8WN-u4GscQoCU054HPVaHPT8fQ86Bl3Aty8Bf2e5Gw6WIpLSFgWd6Nmhiv1ANUcW8vSLxsefWI6N37j-0fCa1fgZefv-M-Kg_dfE-8a33YxzAwN5NB3HCbv7FNsYD1rIg'
            )
          end.to raise_error(
            OpenIDConnect::ResponseObject::IdToken::ExpiredToken,
            'Invalid ID token: Expired token'
          )
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
            nonce: '1656b4264b60af659fce',
            state: 'state',
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
