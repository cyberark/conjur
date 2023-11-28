# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::Strategy) do
  let(:jwt) { { claim_mapping: "alice", nonce: 'nonce' }.stringify_keys }

  let(:mapping) { 'claim_mapping' }
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

  let(:oidc_client) do
    class_double(::Authentication::AuthnOidc::V2::OidcClient).tap do |double|
      allow(double).to receive(:new).and_return(instantiated_oidc_client)
    end
  end

  let(:instantiated_oidc_client) do
    instance_double(::Authentication::AuthnOidc::V2::OidcClient).tap do |double|
      allow(double).to receive(:exchange_code_for_token).and_return(SuccessResponse.new(jwt))
      allow(double).to receive(:oidc_configuration).and_return(SuccessResponse.new({ 'jwks_uri' => 'http://foo.bar.com' }))
    end
  end

  let(:jwt_client) do
    class_double(JWT).tap do |double|
      allow(double).to receive(:decode).and_return([jwt])
    end
  end

  let(:strategy) do
    described_class.new(
      authenticator: authenticator,
      oidc_client: oidc_client,
      jwt_client: jwt_client
    )
  end

  describe('#callback', type: 'unit') do
    context 'when required parameters are present' do
      let(:parameters) { { nonce: 'nonce', code: 'code', code_verifier: 'foo' } }
      context 'when code is successfully exchanged for a validated token' do
        context 'when an identifying claim is found' do
          it 'is successful' do
            response = strategy.callback(parameters: parameters)

            expect(response.success?).to eq(true)
            expect(response.result.class).to eq(Authentication::RoleIdentifier)
            expect(response.result.identifier).to eq('cucumber:user:alice')
            expect(response.result.annotations).to eq({})
          end
        end
        context 'when an identifying claim is not found' do
          context 'when claim_mapping value is not present in the JWT' do
            let(:jwt) { { other_claim_mapping: "alice", nonce: 'nonce' }.stringify_keys }
            it 'is unsuccessful' do
              response = strategy.callback(parameters: parameters)

              expect(response.success?).to eq(false)
              expect(response.message).to eq("Claim 'claim_mapping' was not found in the JWT token")
              expect(response.status).to eq(:unauthorized)
              expect(response.exception.class).to eq(Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty)
            end
          end
        end
      end
      context 'when code is not successfully exchanged for a validated token' do
        let(:instantiated_oidc_client) do
          instance_double(::Authentication::AuthnOidc::V2::OidcClient).tap do |double|
            allow(double).to receive(:exchange_code_for_token).and_return(FailureResponse.new('no dice'))
          end
        end
        it 'is unsuccessful' do
          response = strategy.callback(parameters: parameters)

          expect(response.success?).to eq(false)
          expect(response.message).to eq('no dice')
        end
      end
    end
    context 'when optional parameters are missing' do
      let(:parameters) { { nonce: 'nonce', code: 'code' } }
      it 'is successful' do
        response = strategy.callback(parameters: parameters)

        expect(response.success?).to eq(true)
        expect(response.result.class).to eq(Authentication::RoleIdentifier)
        expect(response.result.identifier).to eq('cucumber:user:alice')
        expect(response.result.annotations).to eq({})
      end
    end

    context 'when required parameters are present' do
      context 'when code is missing' do
        let(:parameters) { { nonce: 'nonce' } }
        it 'is unsuccessful' do
          response = strategy.callback(parameters: parameters)

          expect(response.success?).to eq(false)
          expect(response.message).to eq("Missing parameter: 'code'")
          expect(response.status).to eq(:bad_request)
          expect(response.exception.class).to eq(Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end
      context 'when nonce is missing' do
        let(:parameters) { { code: 'code' } }
        it 'is unsuccessful' do
          response = strategy.callback(parameters: parameters)

          expect(response.success?).to eq(false)
          expect(response.message).to eq("Missing parameter: 'nonce'")
          expect(response.status).to eq(:bad_request)
          expect(response.exception.class).to eq(Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end
      context 'when nonce is different' do
        let(:parameters) { { code: 'code', nonce: 'other-nonce' } }
        it 'is unsuccessful' do
          response = strategy.callback(parameters: parameters)

          expect(response.success?).to eq(false)
          expect(response.message).to eq("Provided nonce does not match the JWT nonce")
          expect(response.status).to eq(:bad_request)
          expect(response.exception.class).to eq(Errors::Authentication::AuthnOidc::NonceVerificationFailed)
        end
      end
    end
  end
end
