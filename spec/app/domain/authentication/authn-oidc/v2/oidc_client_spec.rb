# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::OidcClient) do
  let(:authenticator_args) do
    {
      provider_uri: 'https://dev-92899796.okta.com/oauth2/default',
      redirect_uri: "http://localhost:3000/authn-oidc/okta/cucumber/authenticate",
      client_id: 'super-secret-client-id',
      client_secret: 'super-secret-client-secret',
      claim_mapping: "email",
      account: "bar",
      service_id: "baz"
    }
  end

  let(:oidc_client) do
    described_class.new(
      authenticator: Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(**authenticator_args),
      client: transporter
    )
  end

  let(:transporter) do
    class_double(::Authentication::Util::NetworkTransporter).tap do |double|
      allow(double).to receive(:new).and_return(transport)
    end
  end

  let(:transport) do
    instance_double(::Authentication::Util::NetworkTransporter)
  end

  let(:auth_time) { Time.parse('2022-09-30 17:02:17 +0000') }

  # rubocop:disable Layout:LineLength
  before do
    transport.tap do |double|
      allow(double).to receive(:get)
        .with('https://dev-92899796.okta.com/oauth2/default/.well-known/openid-configuration')
        .and_return(
          SuccessResponse.new(
            JSON.parse('{"issuer":"https://dev-92899796.okta.com/oauth2/default","authorization_endpoint":"https://dev-92899796.okta.com/oauth2/default/v1/authorize","token_endpoint":"https://dev-92899796.okta.com/oauth2/default/v1/token","userinfo_endpoint":"https://dev-92899796.okta.com/oauth2/default/v1/userinfo","registration_endpoint":"https://dev-92899796.okta.com/oauth2/v1/clients","jwks_uri":"https://dev-92899796.okta.com/oauth2/default/v1/keys","response_types_supported":["code","id_token","code_id_token","code token","id_token token","code id_token token"],"response_modes_supported":["query","fragment","form_post","okta_post_message"],"grant_types_supported":["authorization_code","implicit","refresh_token","password","urn:ietf:params:oauth:grant-type:device_code"],"subject_types_supported":["public"],"id_token_signing_alg_values_supported":["RS256"],"scopes_supported":["openid","profile","email","address","phone","offline_access","device_sso"],"token_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"claims_supported":["iss","ver","sub","aud","iat","exp","jti","auth_time","amr","idp","nonce","name","nickname","preferred_username","given_name","middle_name","family_name","email","email_verified","profile","zoneinfo","locale","address","phone_number","picture","website","gender","birthdate","updated_at","at_hash","c_hash"],"code_challenge_methods_supported":["S256"],"introspection_endpoint":"https://dev-92899796.okta.com/oauth2/default/v1/introspect","introspection_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"revocation_endpoint":"https://dev-92899796.okta.com/oauth2/default/v1/revoke","revocation_endpoint_auth_methods_supported":["client_secret_basic","client_secret_post","client_secret_jwt","private_key_jwt","none"],"end_session_endpoint":"https://dev-92899796.okta.com/oauth2/default/v1/logout","request_parameter_supported":true,"request_object_signing_alg_values_supported":["HS256","HS384","HS512","RS256","RS384","RS512","ES256","ES384","ES512"],"device_authorization_endpoint":"https://dev-92899796.okta.com/oauth2/default/v1/device/authorize"}')
          )
        )
    end
  end
  # rubocop:enable Layout:LineLength

  describe '.oidc_configuration' do
    context 'when information endpoint is available' do
      it 'is successful' do
        response = oidc_client.oidc_configuration

        expect(response.success?).to eq(true)
        expect(response.result['jwks_uri']).to eq('https://dev-92899796.okta.com/oauth2/default/v1/keys')
        expect(response.result['token_endpoint']).to eq('https://dev-92899796.okta.com/oauth2/default/v1/token')
      end
    end
    context 'when information endpoint is not available' do
      it 'is unsuccessful' do
        transport.tap do |double|
          allow(double).to receive(:get).with('https://dev-92899796.okta.com/oauth2/default/.well-known/openid-configuration').and_return(FailureResponse.new('failed'))
        end

        response = oidc_client.oidc_configuration

        expect(response.success?).to eq(false)
        expect(response.message).to eq("Authn-OIDC 'baz' provider-uri: 'https://dev-92899796.okta.com/oauth2/default' is unreachable")
      end
    end
  end

  describe '.exchange' do
    context 'code is successfully exchanged for token' do
      # rubocop:disable Layout:LineLength
      before do
        transport.tap do |double|
          allow(double).to receive(:post)
            .with(
              path: 'https://dev-92899796.okta.com/oauth2/default/v1/token',
              body: 'grant_type=authorization_code&scope=true&code=-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw&nonce=7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d&code_verifier=c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauthn-oidc%2Fokta%2Fcucumber%2Fauthenticate',
              basic_auth: %w[super-secret-client-id super-secret-client-secret],
              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
            )
            .and_return(
              SuccessResponse.new(
                JSON.parse('{"token_type":"Bearer","expires_in":3600,"access_token":"eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULkNoVzZRVU1iYllmalZZdGhZT0MxT2FqR3gzNk52NUIteWFTcnNtdTBBM3ciLCJpc3MiOiJodHRwczovL2Rldi05Mjg5OTc5Ni5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6ImFwaTovL2RlZmF1bHQiLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwiY2lkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJ1aWQiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsInNjcCI6WyJlbWFpbCIsInByb2ZpbGUiLCJvcGVuaWQiXSwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJzdWIiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20ifQ.hxsTC4_AO9M-KzYDmOac9KK2cqdvZVEXtB0jagLMEkfdkZ4XTm2h8UBcbdTlwKa1UWbM5y9JuwTeQ5_J3FJP-YMkzsfcrYvvYkAd0V7Dw39CjRh5SFU7y-_ReCWGUp5Ni__yLcfmRl0EUAufs-JauyPX3GiknYD4QPZsfjCl0qGfZ7QrPOFOO4IJu7DuKCNVb-fR9aTS4VGEdff62idOoTKexXAuIaWw9yicSTULGFpIxeyPiVMjRQtpuZAl15rdmdZi2fJqlMEY7fbMY5OzgRcT-KCITk6vzY8DsoJosOZbNBYSvwHBilbcxJYMz3o9xn39ADZIvGX69M-3llbKRQ","scope":"email profile openid","id_token":"eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsIm5hbWUiOiJSb2JlcnQgV2lsbGlhbXMgSUlJIiwiZW1haWwiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZGV2LTkyODk5Nzk2Lm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwianRpIjoiSUQuMFE0Uy1xTEpCaW5fbi1PUHQySVBzYVhOaE8yMjRrLVpqVlFpLVNodUxNNCIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvM3cxeTh0dXVhWWNDVDc1ZDciLCJub25jZSI6IjdlZmNiYmEzNmE5Yjk2ZmRiNTI4NWExNTk2NjVjM2QzODJhYmQ4YjZiMzI4OGZjYzhkIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdC51c2VyM0BteWNvbXBhbnkuY29tIiwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJhdF9oYXNoIjoiY3d4OTNFaTJXdVYzRzZ3MFRiYmJBZyJ9.SrRuxy27rvHveLtC_2lWFpTWXTSc1I4UCDs4jd1pUKD4iBldSLXk7fWEY7VNQFqtHGidOSBD4rOUiSCpphLKHGfLgFLyRlqjU2k4nG8BGqslaEuiN2YhsVDECAjjjctDUazSaDHKsYiPCt4f9w7DeCWShDkG7QLH-CHlUkYzzeBz3bXmxYm2h1LzhMstZldvFTbcB-pKtKauavzhYK2NIb8k86EpXr7tHQ4wbgOUzX6_m8lw-9gMhGZc32vxROiaqu776DmZ7doQwLx3UN3NqRIdhlCThCy4seF_3_YanE73PAhCRNRTiEBZ5svct7XGBw8Vl5VElV7b6lAC21Ni5w"}')
              )
            )
        end
      end
      # rubocop:enable Layout:LineLength
      context 'token is successfully decoded' do
        # rubocop:disable Layout:LineLength
        before do
          transport.tap do |double|
            allow(double).to receive(:get)
              .with('https://dev-92899796.okta.com/oauth2/default/v1/keys')
              .and_return(
                SuccessResponse.new(
                  JSON.parse('{"keys":[{"kty":"RSA","alg":"RS256","kid":"74NNGdtD-kCjuokYDTUhm9UT7ItciF9KWD1SDVKreo4","use":"sig","e":"AQAB","n":"zhlW4oIEvu5wcGQ4ROfpumaqQWluAGi6FIV1Hi-gFuA9Z_Gxw4x3fQnZbpsXsuWlu2Ivfl-9RCiu2AGcpUiH7cX84BWTRtwdOuPXMvOx_g1EUVna1IdVbXSsvWzgi0gOHsv9ZGyoq9BPRccn4m69824SvoAsIi3m-Jr0W3RFe3dCojkGDmrDiH7h8mhR_CjG2IRaQVxc0OqhwOYGAIsivhKQB7YjxqR3fMyUYEpJg3285r5r0-05slJDcUfJ3kILUgAvBBx0fZdLdopHij7hWFaPPKWHW7gKvFlX8h2_IMFMkaGlCF0XQ9S35hiQa12Nqf9frEDa48qcBmUweW67Rw"},{"kty":"RSA","alg":"RS256","kid":"_I6KGcucpmmj1en6JMfUuFB7SDKergpmgfP5nOBucxI","use":"sig","e":"AQAB","n":"40IMCS23bTWYL04XSZ-lwwnKuxVpkULRZYFxUrsYSXt5O-Tob52kIfw_QV_I3qNTZqjbfzSmokifNGF8_O1sQVuENE0vDpxenh05eV8h497sunnhsuOLkl4Y0CqgLWcfH-4qgF8musOPsVBdQIZ7SQ4BNMupgAkgyxENynDDlM4GeAwhu7TYtmtA2eOsj4ut6GrLNk-6KjhHvllmVdH09RJox5cz5atwTNI_LkwK9AHRLCaaM27KNLX498kFDTLPfB27zGwwODLuOy0i6XHskf4fnzrL-ttXliVtt0zgfMKPBCPxkm8Ynk7FRZbKisZRwl82aSyDWfZo-gHU2-U8Bw"}]}')
                )
              )
          end
        end
        # rubocop:enable Layout:LineLength
        context 'when the oidc provider does not require a redirect uri' do
          let(:authenticator_args) do
            {
              provider_uri: 'https://dev-92899796.okta.com/oauth2/default',
              client_id: 'super-secret-client-id',
              client_secret: 'super-secret-client-secret',
              claim_mapping: "email",
              account: "bar",
              service_id: "baz"
            }
          end
          # rubocop:disable Layout:LineLength
          before do
            transport.tap do |double|
              allow(double).to receive(:post)
                .with(
                  path: 'https://dev-92899796.okta.com/oauth2/default/v1/token',
                  body: 'grant_type=authorization_code&scope=true&code=-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw&nonce=7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d&code_verifier=c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
                  basic_auth: %w[super-secret-client-id super-secret-client-secret],
                  headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
                )
                .and_return(
                  SuccessResponse.new(
                    JSON.parse('{"token_type":"Bearer","expires_in":3600,"access_token":"eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULkNoVzZRVU1iYllmalZZdGhZT0MxT2FqR3gzNk52NUIteWFTcnNtdTBBM3ciLCJpc3MiOiJodHRwczovL2Rldi05Mjg5OTc5Ni5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6ImFwaTovL2RlZmF1bHQiLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwiY2lkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJ1aWQiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsInNjcCI6WyJlbWFpbCIsInByb2ZpbGUiLCJvcGVuaWQiXSwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJzdWIiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20ifQ.hxsTC4_AO9M-KzYDmOac9KK2cqdvZVEXtB0jagLMEkfdkZ4XTm2h8UBcbdTlwKa1UWbM5y9JuwTeQ5_J3FJP-YMkzsfcrYvvYkAd0V7Dw39CjRh5SFU7y-_ReCWGUp5Ni__yLcfmRl0EUAufs-JauyPX3GiknYD4QPZsfjCl0qGfZ7QrPOFOO4IJu7DuKCNVb-fR9aTS4VGEdff62idOoTKexXAuIaWw9yicSTULGFpIxeyPiVMjRQtpuZAl15rdmdZi2fJqlMEY7fbMY5OzgRcT-KCITk6vzY8DsoJosOZbNBYSvwHBilbcxJYMz3o9xn39ADZIvGX69M-3llbKRQ","scope":"email profile openid","id_token":"eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsIm5hbWUiOiJSb2JlcnQgV2lsbGlhbXMgSUlJIiwiZW1haWwiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZGV2LTkyODk5Nzk2Lm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwianRpIjoiSUQuMFE0Uy1xTEpCaW5fbi1PUHQySVBzYVhOaE8yMjRrLVpqVlFpLVNodUxNNCIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvM3cxeTh0dXVhWWNDVDc1ZDciLCJub25jZSI6IjdlZmNiYmEzNmE5Yjk2ZmRiNTI4NWExNTk2NjVjM2QzODJhYmQ4YjZiMzI4OGZjYzhkIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdC51c2VyM0BteWNvbXBhbnkuY29tIiwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJhdF9oYXNoIjoiY3d4OTNFaTJXdVYzRzZ3MFRiYmJBZyJ9.SrRuxy27rvHveLtC_2lWFpTWXTSc1I4UCDs4jd1pUKD4iBldSLXk7fWEY7VNQFqtHGidOSBD4rOUiSCpphLKHGfLgFLyRlqjU2k4nG8BGqslaEuiN2YhsVDECAjjjctDUazSaDHKsYiPCt4f9w7DeCWShDkG7QLH-CHlUkYzzeBz3bXmxYm2h1LzhMstZldvFTbcB-pKtKauavzhYK2NIb8k86EpXr7tHQ4wbgOUzX6_m8lw-9gMhGZc32vxROiaqu776DmZ7doQwLx3UN3NqRIdhlCThCy4seF_3_YanE73PAhCRNRTiEBZ5svct7XGBw8Vl5VElV7b6lAC21Ni5w"}')
                  )
                )
            end
          end
          # rubocop:enable Layout:LineLength

          it 'is successful' do
            response =
              travel_to(auth_time) do
                oidc_client.exchange_code_for_token(
                  code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
                  code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
                  nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
                )
              end

            expect(response.success?).to eq(true)
            expect(response.result.class).to eq(String)
            # rubocop:disable Layout:LineLength
            expect(response.result).to eq('eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsIm5hbWUiOiJSb2JlcnQgV2lsbGlhbXMgSUlJIiwiZW1haWwiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZGV2LTkyODk5Nzk2Lm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwianRpIjoiSUQuMFE0Uy1xTEpCaW5fbi1PUHQySVBzYVhOaE8yMjRrLVpqVlFpLVNodUxNNCIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvM3cxeTh0dXVhWWNDVDc1ZDciLCJub25jZSI6IjdlZmNiYmEzNmE5Yjk2ZmRiNTI4NWExNTk2NjVjM2QzODJhYmQ4YjZiMzI4OGZjYzhkIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdC51c2VyM0BteWNvbXBhbnkuY29tIiwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJhdF9oYXNoIjoiY3d4OTNFaTJXdVYzRzZ3MFRiYmJBZyJ9.SrRuxy27rvHveLtC_2lWFpTWXTSc1I4UCDs4jd1pUKD4iBldSLXk7fWEY7VNQFqtHGidOSBD4rOUiSCpphLKHGfLgFLyRlqjU2k4nG8BGqslaEuiN2YhsVDECAjjjctDUazSaDHKsYiPCt4f9w7DeCWShDkG7QLH-CHlUkYzzeBz3bXmxYm2h1LzhMstZldvFTbcB-pKtKauavzhYK2NIb8k86EpXr7tHQ4wbgOUzX6_m8lw-9gMhGZc32vxROiaqu776DmZ7doQwLx3UN3NqRIdhlCThCy4seF_3_YanE73PAhCRNRTiEBZ5svct7XGBw8Vl5VElV7b6lAC21Ni5w')
            # rubocop:enable Layout:LineLength
          end
        end
        context 'when code verifier is not used' do
          before do
            transport.tap do |double|
              # rubocop:disable Layout:LineLength
              allow(double).to receive(:post)
                .with(
                  path: 'https://dev-92899796.okta.com/oauth2/default/v1/token',
                  body: 'grant_type=authorization_code&scope=true&code=-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw&nonce=7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauthn-oidc%2Fokta%2Fcucumber%2Fauthenticate',
                  basic_auth: %w[super-secret-client-id super-secret-client-secret],
                  headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
                )
                .and_return(
                  SuccessResponse.new(
                    JSON.parse('{"token_type":"Bearer","expires_in":3600,"access_token":"eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULkNoVzZRVU1iYllmalZZdGhZT0MxT2FqR3gzNk52NUIteWFTcnNtdTBBM3ciLCJpc3MiOiJodHRwczovL2Rldi05Mjg5OTc5Ni5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6ImFwaTovL2RlZmF1bHQiLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwiY2lkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJ1aWQiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsInNjcCI6WyJlbWFpbCIsInByb2ZpbGUiLCJvcGVuaWQiXSwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJzdWIiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20ifQ.hxsTC4_AO9M-KzYDmOac9KK2cqdvZVEXtB0jagLMEkfdkZ4XTm2h8UBcbdTlwKa1UWbM5y9JuwTeQ5_J3FJP-YMkzsfcrYvvYkAd0V7Dw39CjRh5SFU7y-_ReCWGUp5Ni__yLcfmRl0EUAufs-JauyPX3GiknYD4QPZsfjCl0qGfZ7QrPOFOO4IJu7DuKCNVb-fR9aTS4VGEdff62idOoTKexXAuIaWw9yicSTULGFpIxeyPiVMjRQtpuZAl15rdmdZi2fJqlMEY7fbMY5OzgRcT-KCITk6vzY8DsoJosOZbNBYSvwHBilbcxJYMz3o9xn39ADZIvGX69M-3llbKRQ","scope":"email profile openid","id_token":"eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsIm5hbWUiOiJSb2JlcnQgV2lsbGlhbXMgSUlJIiwiZW1haWwiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZGV2LTkyODk5Nzk2Lm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwianRpIjoiSUQuMFE0Uy1xTEpCaW5fbi1PUHQySVBzYVhOaE8yMjRrLVpqVlFpLVNodUxNNCIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvM3cxeTh0dXVhWWNDVDc1ZDciLCJub25jZSI6IjdlZmNiYmEzNmE5Yjk2ZmRiNTI4NWExNTk2NjVjM2QzODJhYmQ4YjZiMzI4OGZjYzhkIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdC51c2VyM0BteWNvbXBhbnkuY29tIiwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJhdF9oYXNoIjoiY3d4OTNFaTJXdVYzRzZ3MFRiYmJBZyJ9.SrRuxy27rvHveLtC_2lWFpTWXTSc1I4UCDs4jd1pUKD4iBldSLXk7fWEY7VNQFqtHGidOSBD4rOUiSCpphLKHGfLgFLyRlqjU2k4nG8BGqslaEuiN2YhsVDECAjjjctDUazSaDHKsYiPCt4f9w7DeCWShDkG7QLH-CHlUkYzzeBz3bXmxYm2h1LzhMstZldvFTbcB-pKtKauavzhYK2NIb8k86EpXr7tHQ4wbgOUzX6_m8lw-9gMhGZc32vxROiaqu776DmZ7doQwLx3UN3NqRIdhlCThCy4seF_3_YanE73PAhCRNRTiEBZ5svct7XGBw8Vl5VElV7b6lAC21Ni5w"}')
                  )
                )
              # rubocop:enable Layout:LineLength
            end
          end
          it 'returns the token claims' do
            response =
              travel_to(auth_time) do
                oidc_client.exchange_code_for_token(code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw', nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d')
              end

            expect(response.success?).to eq(true)
            expect(response.result.class).to eq(String)
            # rubocop:disable Layout:LineLength
            expect(response.result).to eq('eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsIm5hbWUiOiJSb2JlcnQgV2lsbGlhbXMgSUlJIiwiZW1haWwiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZGV2LTkyODk5Nzk2Lm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwianRpIjoiSUQuMFE0Uy1xTEpCaW5fbi1PUHQySVBzYVhOaE8yMjRrLVpqVlFpLVNodUxNNCIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvM3cxeTh0dXVhWWNDVDc1ZDciLCJub25jZSI6IjdlZmNiYmEzNmE5Yjk2ZmRiNTI4NWExNTk2NjVjM2QzODJhYmQ4YjZiMzI4OGZjYzhkIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdC51c2VyM0BteWNvbXBhbnkuY29tIiwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJhdF9oYXNoIjoiY3d4OTNFaTJXdVYzRzZ3MFRiYmJBZyJ9.SrRuxy27rvHveLtC_2lWFpTWXTSc1I4UCDs4jd1pUKD4iBldSLXk7fWEY7VNQFqtHGidOSBD4rOUiSCpphLKHGfLgFLyRlqjU2k4nG8BGqslaEuiN2YhsVDECAjjjctDUazSaDHKsYiPCt4f9w7DeCWShDkG7QLH-CHlUkYzzeBz3bXmxYm2h1LzhMstZldvFTbcB-pKtKauavzhYK2NIb8k86EpXr7tHQ4wbgOUzX6_m8lw-9gMhGZc32vxROiaqu776DmZ7doQwLx3UN3NqRIdhlCThCy4seF_3_YanE73PAhCRNRTiEBZ5svct7XGBw8Vl5VElV7b6lAC21Ni5w')
            # rubocop:enable Layout:LineLength
          end
        end
        context 'token nonce matches the nonce in the JWT token' do
          let(:authenticator) do
          end
          it 'returns the token claims' do
            response =
              travel_to(auth_time) do
                oidc_client.exchange_code_for_token(
                  code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
                  code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
                  nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
                )
              end

            expect(response.success?).to eq(true)
            expect(response.result.class).to eq(String)
            # rubocop:disable Layout:LineLength
            expect(response.result).to eq('eyJraWQiOiI3NE5OR2R0RC1rQ2p1b2tZRFRVaG05VVQ3SXRjaUY5S1dEMVNEVktyZW80IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHU1Z2tvNmRmNDRqMmZHcDVkNyIsIm5hbWUiOiJSb2JlcnQgV2lsbGlhbXMgSUlJIiwiZW1haWwiOiJ0ZXN0LnVzZXIzQG15Y29tcGFueS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZGV2LTkyODk5Nzk2Lm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiMG9hM3czeGlnNnJIaXU5eVQ1ZDciLCJpYXQiOjE2NjQ1NTgwNzgsImV4cCI6MTY2NDU2MTY3OCwianRpIjoiSUQuMFE0Uy1xTEpCaW5fbi1PUHQySVBzYVhOaE8yMjRrLVpqVlFpLVNodUxNNCIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvM3cxeTh0dXVhWWNDVDc1ZDciLCJub25jZSI6IjdlZmNiYmEzNmE5Yjk2ZmRiNTI4NWExNTk2NjVjM2QzODJhYmQ4YjZiMzI4OGZjYzhkIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdC51c2VyM0BteWNvbXBhbnkuY29tIiwiYXV0aF90aW1lIjoxNjY0NTU3ODUzLCJhdF9oYXNoIjoiY3d4OTNFaTJXdVYzRzZ3MFRiYmJBZyJ9.SrRuxy27rvHveLtC_2lWFpTWXTSc1I4UCDs4jd1pUKD4iBldSLXk7fWEY7VNQFqtHGidOSBD4rOUiSCpphLKHGfLgFLyRlqjU2k4nG8BGqslaEuiN2YhsVDECAjjjctDUazSaDHKsYiPCt4f9w7DeCWShDkG7QLH-CHlUkYzzeBz3bXmxYm2h1LzhMstZldvFTbcB-pKtKauavzhYK2NIb8k86EpXr7tHQ4wbgOUzX6_m8lw-9gMhGZc32vxROiaqu776DmZ7doQwLx3UN3NqRIdhlCThCy4seF_3_YanE73PAhCRNRTiEBZ5svct7XGBw8Vl5VElV7b6lAC21Ni5w')
            # rubocop:enable Layout:LineLength
          end
        end
      end
    end
    context 'token response is empty' do
      # rubocop:disable Layout:LineLength
      before do
        transport.tap do |double|
          allow(double).to receive(:post)
            .with(
              path: 'https://dev-92899796.okta.com/oauth2/default/v1/token',
              body: 'grant_type=authorization_code&scope=true&code=-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw&nonce=7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d&code_verifier=c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauthn-oidc%2Fokta%2Fcucumber%2Fauthenticate',
              basic_auth: %w[super-secret-client-id super-secret-client-secret],
              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
            )
            .and_return(
              FailureResponse.new('empty response')
            )
        end
      end
      # rubocop:enable Layout:LineLength
      it 'is unsuccessful' do
        response =
          travel_to(auth_time) do
            oidc_client.exchange_code_for_token(
              code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
              code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
              nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
            )
          end

        expect(response.success?).to eq(false)
        expect(response.message).to eq('empty response')
        expect(response.exception.class).to eq(Errors::Authentication::AuthnOidc::TokenRetrievalFailed)
        expect(response.status).to eq(:bad_request)
      end
    end
    context 'token does not have a valid bearer token' do
      # rubocop:disable Layout:LineLength
      before do
        transport.tap do |double|
          allow(double).to receive(:post)
            .with(
              path: 'https://dev-92899796.okta.com/oauth2/default/v1/token',
              body: 'grant_type=authorization_code&scope=true&code=-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw&nonce=7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d&code_verifier=c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauthn-oidc%2Fokta%2Fcucumber%2Fauthenticate',
              basic_auth: %w[super-secret-client-id super-secret-client-secret],
              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
            )
            .and_return(
              SuccessResponse.new(
                JSON.parse('{"token_type":"Bearer","expires_in":3600,"scope":"email profile openid"}')
              )
            )
        end
      end
      # rubocop:enable Layout:LineLength
      it 'is unsuccessful' do
        response =
          travel_to(auth_time) do
            oidc_client.exchange_code_for_token(
              code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
              code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
              nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d'
            )
          end

        expect(response.success?).to eq(false)
        expect(response.message).to eq('Bearer Token is empty')
        expect(response.exception.class).to eq(Errors::Authentication::AuthnOidc::TokenRetrievalFailed)
        expect(response.status).to eq(:bad_request)
      end
    end
  end
end
