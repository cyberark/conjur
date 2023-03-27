# frozen_string_literal: true

require 'spec_helper'

# NOTES:
#
# We need to be sure to expire the JWT cache before any calls to verify a JWT token. If not
# we'll see intermittent "flapping" test failures depending on the order the tests are
# executed ("Randomized with seed 14446").
#
RSpec.describe(Authentication::AuthnOidc::V2::Strategy) do
  let(:authenticator_params) { {} }
  let(:params) { {} }
  subject do
    Authentication::AuthnJwt::V2::Strategy.new(
      authenticator: Authentication::AuthnJwt::V2::DataObjects::Authenticator.new(
        **{ account: 'rspec', service_id: 'bar' }.merge(authenticator_params),
        **params
      )
    )
  end
  let(:jwks_endpoint) { 'http://jwks_py:8090/authn-jwt-check-standard-claims/RS256' }

  describe '.callback', type: 'unit' do
    context 'jwks' do
      context 'basic call', vcr: 'authenticators/authn-jwt/v2/jwks-simple' do
        let(:authenticator_params) { { jwks_uri: jwks_endpoint } }
        let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2ODAyODkyODksImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDQ4OSwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.g4CBtwxSTcdvOWnlQTutqlYHD23bEA9LVLU2MS8UDW2pZSIucw_Dem0_2u3iJNZbTqATMpcFXxn2oi7VrsZbpl9pQ6PWSo4WwTHXoztWae4OInJ29cSQko0K4IExRSxyD3kM14eOp5ueaesa53O-8557fSUGq0qPcLqAxSgY31Y' }
        it 'returns successfully' do
          Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
          travel_to(Time.parse('2023-03-25 15:19:00 +0000')) do
            expect(subject.callback(request_body: "jwt=#{token}")).to eq({
              'exp' => 1680289289,
              'host' => 'myapp',
              'project_id' => 'myproject',
              'iat' => 1679684489
            })
          end
        end
      end

      context 'with audience and issuer', vcr: 'authenticators/authn-jwt/v2/jwks-audience-and-issuer' do
        let(:authenticator_params) { { jwks_uri: jwks_endpoint, audience: 'rspec', issuer: 'Conjur Unit Testing' } }
        let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJhdWQiOiJyc3BlYyIsImV4cCI6MTY4MDI4OTQxMCwiaG9zdCI6Im15YXBwIiwiaWF0IjoxNjc5Njg0NjEwLCJpc3MiOiJDb25qdXIgVW5pdCBUZXN0aW5nIiwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.N_BK8qjNxGa8my0BaywrVAsQkxQlPN7QmK7wNu8DqJIFtK7OiH2qpmTMKzTIBiklSX-XZ-i3DG-_TmMGF0SCIFxyt1BbIhkEiHFS7YI9yj9tVkAZc0Ma_vQ6T8Jh9bfvBl3xZOwIvznIZZ_xQWm00m7jNO9pn-bQpL4L6-ZPRpY' }
        it 'returns successfully' do
          Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
          travel_to(Time.parse('2023-03-25 15:19:00 +0000')) do
            expect(subject.callback(request_body: "jwt=#{token}")).to eq({
              'exp' => 1680289410,
              'host' => 'myapp',
              'project_id' => 'myproject',
              'iat' => 1679684610,
              'aud' => 'rspec',
              'iss' => 'Conjur Unit Testing'
            })
          end
        end
      end
      context 'when request is bad' do
        let(:authenticator_params) { { jwks_uri: jwks_endpoint } }
        context 'when request body is empty' do
          it 'raises an error' do
            # binding.pry
            expect { subject.callback(request_body: "") }.to raise_error(
              Errors::Authentication::RequestBody::MissingRequestParam
            )
          end
        end
        context 'when token is missing' do
          it 'raises an error' do
            expect { subject.callback(request_body: "jwt=") }.to raise_error(
              Errors::Authentication::RequestBody::MissingRequestParam
            )
          end
        end
        context 'when jwt has no claims' do
          let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.e30.rfDTYUvLc6B426mB7SvQgQWUUC1cZiH01jiUuL40nNvuse_h8fjbtoZ2FuLAlaOrLcmrCqyWgT2iEUfiqsOwIPsyBbEuIMMMlg4eTBk2Ed1i_1g4NGhhPRbDMTGCF9Z7ERyV85CrWqxXX0Z7So0gwaoMH_9fGN56V4hWPiLdTzw' }
          it 'raises an error', vcr: 'authenticators/authn-jwt/v2/empty-jwt' do
            Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
            expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
              Errors::Authentication::AuthnJwt::MissingToken
            )
          end
        end
        context 'when jwt is expired' do
          let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2NzkwNzk1MDMsImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDMwMywicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.DG2l0xPtvcXsoUWoTgyFgVuOZ-OGGxDXTgR1yFu_c2Tg1-qxTElQ7O12aZYj2E7BkXBohyxd7ZLOzWgan8i82xAlETJ7RVe7t1vcc7d8cRv0DuKgYq1EdvXruSZEQap87APmth8Vzo7n6AUQ4E7UyknJVn14zXCqu_Hwf7F3tNc' }
          it 'raises an error', vcr: 'authenticators/authn-jwt/v2/expired-jwt'  do
            travel_to(Time.parse('2023-03-25 15:19:00 +0000')) do
              Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
              expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
                Errors::Authentication::Jwt::TokenExpired
              )
            end
          end
        end
        context 'when jwt is malformed' do
          context 'missing characters' do
            let(:token) { 'eyhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2ODAyODkyODksImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDQ4OSwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.g4CBtwxSTcdvOWnlQTutqlYHD23bEA9LVLU2MS8UDW2pZSIucw_Dem0_2u3iJNZbTqATMpcFXxn2oi7VrsZbpl9pQ6PWSo4WwTHXoztWae4OInJ29cSQko0K4IExRSxyD3kM14eOp5ueaesa53O-8557fSUGq0qPcLqAxSgY31Y' }
            it 'raises an error' do
              expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
                Errors::Authentication::Jwt::TokenDecodeFailed
              )
            end
          end
          context 'extra characters' do
            let(:token) { 'eyJJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2ODAyODkyODksImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDQ4OSwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.g4CBtwxSTcdvOWnlQTutqlYHD23bEA9LVLU2MS8UDW2pZSIucw_Dem0_2u3iJNZbTqATMpcFXxn2oi7VrsZbpl9pQ6PWSo4WwTHXoztWae4OInJ29cSQko0K4IExRSxyD3kM14eOp5ueaesa53O-8557fSUGq0qPcLqAxSgY31Y' }
            it 'raises an error' do
              expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
                Errors::Authentication::Jwt::TokenDecodeFailed
              )
            end
          end
          context 'extra segments' do
            let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2ODAyODkyODksImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDQ4OSwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.g4CBtwxSTcdvOWnlQTutqlYHD23bEA9LVLU2MS8UDW2pZSIucw_Dem0_2u3iJNZbTqATMpcFXxn2oi7VrsZbpl9pQ6PWSo4WwTHXoztWae4OInJ29cSQko0K4IExRSxyD3kM14eOp5ueaesa53O-8557fSUGq0qPcLqAxSgY31Y.Zm9vYmFy' }
            it 'raises an error' do
              expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
                Errors::Authentication::Jwt::RequestBodyMissingJWTToken
              )
            end
          end
          context 'too few segments' do
            let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2ODAyODkyODksImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDQ4OSwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9' }
            it 'raises an error' do
              expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
                Errors::Authentication::Jwt::RequestBodyMissingJWTToken
              )
            end
          end
          context 'missing required claim' do
            let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJob3N0IjoibXlhcHAifQ.ccu03AzeOupvjBetjyTyC-202ZUm-dvEeCIKklNY6cTNTknXX0kbUTEqBSfrSxhbATSabLW1BYpPvKPkiwh1trD8cAiE5PSTExtllwv82yPjwwItEgrEiqGWiAxWM0VlFxFQRVP-ndoXxUey7wJ3yo8DeyqLU8alzF25KyHb51g' }
            it 'raises an error', vcr: 'authenticators/authn-jwt/v2/missing-required-claims' do
              Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
              expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
                Errors::Authentication::AuthnJwt::MissingMandatoryClaim
              )
            end
          end
        end
      end
    end
    context 'with OIDC Provider' do
      context 'when provider is invalid' do
        let(:authenticator_params) { { provider_uri: 'http://bad-oidc-url.com' } }
        let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2ODAyODkyODksImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDQ4OSwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.g4CBtwxSTcdvOWnlQTutqlYHD23bEA9LVLU2MS8UDW2pZSIucw_Dem0_2u3iJNZbTqATMpcFXxn2oi7VrsZbpl9pQ6PWSo4WwTHXoztWae4OInJ29cSQko0K4IExRSxyD3kM14eOp5ueaesa53O-8557fSUGq0qPcLqAxSgY31Y' }
        it 'raises an error', vcr: 'authenticators/authn-jwt/v2/bad-oidc-provider' do
          Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
          expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
            Errors::Authentication::OAuth::ProviderDiscoveryFailed
          )
        end
      end
      context 'when provider is valid' do
        let(:authenticator_params) do
          {
            provider_uri: 'https://keycloak:8443/auth/realms/master'
          }
        end
        let(:token) { 'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJfeFB6Q1lNVlFFMXZEZTRlNnNzajNseDR6M1pTdHFNaDJ0V2MycDBYMEs4In0.eyJqdGkiOiIxZTQyYWZkZS02NmUyLTQ3ZjUtYjkwNi02MmM0OTliMjkyYWQiLCJleHAiOjE2Nzk2OTc1MDYsIm5iZiI6MCwiaWF0IjoxNjc5Njk3NDQ2LCJpc3MiOiJodHRwOi8va2V5Y2xvYWs6ODA4MC9hdXRoL3JlYWxtcy9tYXN0ZXIiLCJhdWQiOiJjb25qdXJDbGllbnQiLCJzdWIiOiJkY2ZkZTRhYi1iMWI4LTRhMGEtODU5YS1lMzgxMzNhMmU0NGYiLCJ0eXAiOiJJRCIsImF6cCI6ImNvbmp1ckNsaWVudCIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjQ3YzM0YzE3LTRjZGMtNGYxZS04MGNiLTE5NzNjZDUxYzc1MyIsImFjciI6IjEiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsInByZWZlcnJlZF91c2VybmFtZSI6ImFsaWNlIiwiZW1haWwiOiJhbGljZUBjb25qdXIubmV0In0.X_-FM3vmkm9IAd1wmYDY0pTMoiGquRwisT_N5kPbPvahRWKcBnkQFriXYH5snU5FYuAIRiFkKs0jFod13XoYCE653_FsMmCYNAPx9K4iKkkg0ZhbAQcJQUd_YKbTozpSxnrY7pg3brfhmJCFjBgNOJISWw1vu9Qspkwu_tF9kIbPV5WqoJpyBs4T1FSmoGCsNs0nuuBVJq-Q-ytUfvujxq_rPiIqoUZ-n33d7q-cYDtQaEcvmLzlwJLVYZuxh-YNZpSKXRuC2HSo-O_XiwFITDg6OZClgSe3m_yLSWxjVDiXJoLyXXbz2D_i7p48f9n0faOS0oMYPAlxG30VEraUKw' }
        it 'returns successfully', vcr: 'authenticators/authn-jwt/v2/good-oidc-provider' do
          Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
          travel_to(Time.parse("2023-03-24 22:38:00 +0000")) do
            expect(subject.callback(request_body: "jwt=#{token}")).to eq({
              'acr' => '1',
              'aud' => 'conjurClient',
              'auth_time' => 0,
              'azp' => 'conjurClient',
              'email' => 'alice@conjur.net',
              'email_verified' => false,
              'exp' => 1679697506,
              'iat' => 1679697446,
              'iss' => 'http://keycloak:8080/auth/realms/master',
              'jti' => '1e42afde-66e2-47f5-b906-62c499b292ad',
              'nbf' => 0,
              'preferred_username' => 'alice',
              'session_state' => '47c34c17-4cdc-4f1e-80cb-1973cd51c753',
              'sub' => 'dcfde4ab-b1b8-4a0a-859a-e38133a2e44f',
              'typ' => 'ID'
            })
          end
        end
      end
    end

    context 'with public keys' do
      context 'when public keys are invalid' do
        let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2ODAyODkyODksImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDQ4OSwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.g4CBtwxSTcdvOWnlQTutqlYHD23bEA9LVLU2MS8UDW2pZSIucw_Dem0_2u3iJNZbTqATMpcFXxn2oi7VrsZbpl9pQ6PWSo4WwTHXoztWae4OInJ29cSQko0K4IExRSxyD3kM14eOp5ueaesa53O-8557fSUGq0qPcLqAxSgY31Y' }
        context 'when empty hash' do
          let(:authenticator_params) { { public_keys: '{}' } }
          it 'raises an error' do
            expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
              Errors::Authentication::AuthnJwt::InvalidPublicKeys
            )
          end
        end
        context 'when value is empty' do
          let(:authenticator_params) { { public_keys: '{"type": "jwks", "value": {}}' } }
          it 'raises an error' do
            expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
              Errors::Authentication::AuthnJwt::InvalidPublicKeys
            )
          end
        end
        context 'when no keys are present' do
          let(:authenticator_params) { { public_keys: '{"type": "jwks", "value": {"keys": []}}' } }
          it 'raises an error' do
            expect { subject.callback(request_body: "jwt=#{token}") }.to raise_error(
              Errors::Authentication::Jwt::TokenDecodeFailed
            )
          end
        end
      end
      context 'when public keys are valid' do
        let(:authenticator_params) { { public_keys: '{"type": "jwks", "value": {"keys": [{"e": "AQAB", "kty": "RSA", "n": "ugwppRMuZ0uROdbPewhNUS4219DlBiwXaZOje-PMXdfXRw8umH7IJ9bCIya6ayolap0YWyFSDTTGStRBIbmdY9HKJ25XqkRrVHlUAfBBS_K7zlfoF3wMxmc_sDyXBUET7R3VaDO6A1CuGYwQ5Shj-bSJa8RmOH0OlwSlhr0fKME","kid": "FlpP5WEr5YFZtEYbGH6E-JtWOHk-edj4hPiGOvnU1fY"}]}}' } }
        let(:token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkZscFA1V0VyNVlGWnRFWWJHSDZFLUp0V09Iay1lZGo0aFBpR092blUxZlkifQ.eyJleHAiOjE2ODAyODkyODksImhvc3QiOiJteWFwcCIsImlhdCI6MTY3OTY4NDQ4OSwicHJvamVjdF9pZCI6Im15cHJvamVjdCJ9.g4CBtwxSTcdvOWnlQTutqlYHD23bEA9LVLU2MS8UDW2pZSIucw_Dem0_2u3iJNZbTqATMpcFXxn2oi7VrsZbpl9pQ6PWSo4WwTHXoztWae4OInJ29cSQko0K4IExRSxyD3kM14eOp5ueaesa53O-8557fSUGq0qPcLqAxSgY31Y' }
        it 'returns successfully' do
          travel_to(Time.parse('2023-03-25 15:19:00 +0000')) do
            expect(subject.callback(request_body: "jwt=#{token}")).to eq({
              'exp' => 1680289289,
              'host' => 'myapp',
              'project_id' => 'myproject',
              'iat' => 1679684489
            })
          end
        end
      end
    end
  end

  describe '.verify_status' do
    context 'when configured with a jwks uri' do
      let(:authenticator_params) { { jwks_uri: jwks_endpoint } }
      it 'returns successfully', vcr: 'authenticators/authn-jwt/v2/jwks-simple' do
        Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
        expect { subject.verify_status }.not_to raise_error
      end
      context 'when certificate chain is required to connect to JWKS endpoint' do
        let(:authenticator_params) do
          {
            jwks_uri: 'https://chained.mycompany.local/ca-cert-ONYX-15315.json',
            ca_cert: "-----BEGIN CERTIFICATE-----\nMIIFpzCCA4+gAwIBAgIUa38OC1w7nXbxeymtZM4M3WX1ONEwDQYJKoZIhvcNAQEL\nBQAwWzELMAkGA1UEBhMCVVMxFjAUBgNVBAgMDU1hc3NhY2h1c2V0dHMxETAPBgNV\nBAoMCEN5YmVyQXJrMQ8wDQYDVQQLDAZDb25qdXIxEDAOBgNVBAMMB1Jvb3QgQ0Ew\nHhcNMjMwMTA1MjEzMzA4WhcNNDIxMjMxMjEzMzA4WjBbMQswCQYDVQQGEwJVUzEW\nMBQGA1UECAwNTWFzc2FjaHVzZXR0czERMA8GA1UECgwIQ3liZXJBcmsxDzANBgNV\nBAsMBkNvbmp1cjEQMA4GA1UEAwwHUm9vdCBDQTCCAiIwDQYJKoZIhvcNAQEBBQAD\nggIPADCCAgoCggIBAMDYV+ZWssP1NHCYnH+s3iSUmn9StMT6/u6BOCDCCBkIxL1I\nWLZxTJWifNt9he+swaIBcqTUENb/xdk1I3YbTU1PLoj4v/bLC+Ust/IwbWT3emfk\nVqfEk927pZT7/2x8u9ddhZfJ6j4z4J/f9v3PXFifGF28owFsLCR4hLztnh2QvPr3\n3IyRjY8NUymaOhjNLITEIS4xxAXtc0PKVvN6yjSCyjskVteSs2K/QUy4KByl7vKk\nq55Hps54CPcgIh3aUp35uOKzigV+5KNsr5AeRIlZwH5Jy57q6EZfWb8SqFANJys0\nYpHuG8r65d+twG4N2BMpeXjlxK9JsJkmcixFerUSkWoCfByXV7vAsSKz4I2WyjqJ\nhi1str4FC2Wh8PGt8G4RlNdTNKH3/b0Am7axtULG/SJkEzSbba3dqbkvh1kfIJOC\ngUS+VXehouzDg2KSsVQhK4yg8Sq9a2eb5F05hx19u7fR4398Wbez9x3JW3Ys6V71\n9ParmR1PKzie0w3aL2MBG8ohbAoZEvFfx3Ak6joZKGjvgT3Y8Ry6FOb06vwRCLPd\npgSZ7giRkcs9sA4G2C8BmKvVFA5EBViTYIQwn1j8Tr05J/2z73CofcXGIic82b6G\nDcqwSzFzLRdvD3/KY2bqc19/4yPYDWN/PYpxPg+xF3IqW4FosP1+JMCt3YAbAgMB\nAAGjYzBhMB0GA1UdDgQWBBTpba+vKPK2l5/RZEZRtoBIdGSZXzAfBgNVHSMEGDAW\ngBTpba+vKPK2l5/RZEZRtoBIdGSZXzAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB\n/wQEAwIBhjANBgkqhkiG9w0BAQsFAAOCAgEAQdYZwOmosQHAX4IhTuKPyoFK0dGR\n1bKmuDCS9FudjqGiYN7ZoExjSttEnSbVd7+ylU/Xtp+3GLQDK5+fLVgxFr0ZGFa7\nvBRJWFn2PnGaTQQrF3QV35mQpsF4SsDrmAu9loLt0M4KdIMMPBYtUrPuTQlMButB\nhTZ6xYIX5CmWxIZgZJkJ/tkc5ER4cOLwz9JNHpthx3pjz4XQ95d7gXTSzYOtKEWA\nHPqryj3XiKtP+jHVOuYYm5ymEzaMtQDkNOGMsLJJ0Xex6ezlFOstxRpR3kREJvQZ\nbGG3z1yXQotLLDlwc3ihMyNtuERNbeJCbuL97etQHDrBoFV07zRizFRMc2yLqbpS\nsLEn8Ue7qlZIPTu/JJbBscYy1984NMlnogyT/dUeqQIksxZxmFtD05wfUJsxQZcW\nGjqg81wTpoRuWt45+Li/u949AXBghHm+f3jOMOnmIAxodcrbzSVnuKScBgwHq3KM\n1/UIMH7qL/ecB2/oNSpysJa/X1oKA3xz5y7S2HvFgsignyNEHXZz4S6Zlxg4kyac\nP/sVt64wIsZYMVKPOPup/267CLvYYjNkTGuoQdZzTr/MGDMgJYMY8oBsdfIlZIeh\ns5we2kbKwQY5J/+rnzhqIaP7Pr3wA1m764gdfzmrghoq77nz3hZTAXL/3X5jwEYI\nXE0utcwsw4BKKIc=\n-----END CERTIFICATE-----\n"
          }
        end
        it 'returns successfully', vcr: 'authenticators/authn-jwt/v2/jwks-status-certificate-chain' do
          Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
          expect { subject.verify_status }.not_to raise_error
        end
      end
      context 'jwks uri is bad' do
        let(:authenticator_params) { { jwks_uri: 'http://foo.bar.com' } }
        it 'returns successfully', vcr: 'authenticators/authn-jwt/v2/bad-jwks-endpoint' do
          Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
          expect { subject.verify_status }.to raise_error(
            Errors::Authentication::AuthnJwt::FetchJwksKeysFailed
          )
        end
      end
      context 'jwks request is cached' do
        it 'returns successfully', vcr: 'authenticators/authn-jwt/v2/jwks-simple' do
          Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
          expect { subject.verify_status }.not_to raise_error
          expect { subject.verify_status }.not_to raise_error
        end
      end
      context 'when an HTTP error occurs reaching the JWKS endpoint' do
        context 'endpoint return an error code that is not 200'  do
          let(:authenticator_params) { { jwks_uri: 'https://www.google.com/foo-barz' } }
          it 'raises an error', vcr: 'authenticators/authn-jwt/v2/jwks-missing-path' do
            Rails.cache.delete('authenticators/authn-jwt/rspec-bar/jwks-json')
            expect { subject.verify_status }.to raise_error(
              Errors::Authentication::AuthnJwt::FetchJwksKeysFailed
            )
          end
        end
      end
    end
  end
end
