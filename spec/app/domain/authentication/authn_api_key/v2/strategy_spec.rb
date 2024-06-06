# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnApiKey::V2::Strategy) do
  let(:authenticator) { Authentication::AuthnApiKey::V2::DataObjects::Authenticator.new(account: 'default') }
  let(:parameters) { { id: params_id, account: 'default' } }

  let(:role) { double(::Role) }
  let(:credentials) { double(::Credentials) }
  let(:credential) { double(::Credentials) }

  let(:strategy) do
    Authentication::AuthnApiKey::V2::Strategy.new(
      authenticator: authenticator,
      role: role,
      credentials: credentials
    )
  end

  describe '.callback' do
    let(:request_body) { 'abc123' }
    context 'when role is a user' do
      let(:params_id) { 'foo-bar' }
      let(:conjur_role_identifier) { 'default:user:foo-bar' }
      context 'when Role is found' do
        before do
          expect(role).to receive(:[]).with(conjur_role_identifier).and_return(::Role.new)
        end
        context 'when Credential is present' do
          before do
            expect(credentials).to receive(:[]).with(conjur_role_identifier).and_return(credential)
          end
          context 'when provided API key matches the stored API key' do
            before do
              expect(credential).to receive(:valid_api_key?).with('abc123').and_return(true)
            end
            it 'is successful' do
              response = strategy.callback(request_body: request_body, parameters: parameters)

              expect(response.success?).to eq(true)
              expect(response.result.class).to eq(Authentication::RoleIdentifier)
              expect(response.result.identifier).to eq(conjur_role_identifier)
              expect(response.result.annotations).to eq({})
            end
            context 'when role id is prefixed with user/' do
              let(:params_id) { 'user/foo-bar' }
              let(:conjur_role_identifier) { 'default:user:foo-bar' }

              it 'is successful' do
                response = strategy.callback(request_body: request_body, parameters: parameters)

                expect(response.success?).to eq(true)
                expect(response.result.class).to eq(Authentication::RoleIdentifier)
                expect(response.result.identifier).to eq(conjur_role_identifier)
                expect(response.result.annotations).to eq({})
              end
            end
          end
          context 'when provided API key does not match the stored API key' do
            before do
              expect(credential).to receive(:valid_api_key?).with('abc123').and_return(false)
            end
            it 'is unsuccessful' do
              response = strategy.callback(request_body: request_body, parameters: parameters)

              expect(response.success?).to eq(false)
              expect(response.message.class).to eq(Authentication::RoleIdentifier)
              expect(response.message.identifier).to eq(conjur_role_identifier)
              expect(response.message.annotations).to eq({})
              expect(response.status).to eq(:unauthorized)
              expect(response.exception.class).to eq(Errors::Conjur::ApiKeyNotFound)
            end
          end
        end
        context 'When Credential is not found' do
          before do
            expect(credentials).to receive(:[]).with(conjur_role_identifier).and_return(nil)
          end

          it 'is unsuccessful' do
            response = strategy.callback(request_body: request_body, parameters: parameters)

            expect(response.success?).to eq(false)
            expect(response.message.class).to eq(Authentication::RoleIdentifier)
            expect(response.message.identifier).to eq(conjur_role_identifier)
            expect(response.message.annotations).to eq({})
            expect(response.status).to eq(:unauthorized)
            expect(response.exception.class).to eq(Errors::Authentication::RoleHasNoCredentials)
          end
        end
      end
      context 'when Role is not found' do
        before do
          expect(role).to receive(:[]).with(conjur_role_identifier).and_return(nil)
        end

        it 'is unsuccessful' do
          response = strategy.callback(request_body: request_body, parameters: parameters)

          expect(response.success?).to eq(false)
          expect(response.message.class).to eq(Authentication::RoleIdentifier)
          expect(response.message.identifier).to eq(conjur_role_identifier)
          expect(response.message.annotations).to eq({})
          expect(response.status).to eq(:unauthorized)
          expect(response.exception.class).to eq(Errors::Authentication::Security::RoleNotFound)
        end
      end
    end
    context 'when role is a host' do
      let(:params_id) { 'host/foo-bar' }
      let(:conjur_role_identifier) { 'default:host:foo-bar' }
      context 'when Role is found' do
        before do
          expect(role).to receive(:[]).with(conjur_role_identifier).and_return(::Role.new)
        end
        context 'when Credential is present' do
          before do
            expect(credentials).to receive(:[]).with(conjur_role_identifier).and_return(credential)
          end
          context 'when provided API key matches the stored API key' do
            before do
              expect(credential).to receive(:valid_api_key?).with('abc123').and_return(true)
            end
            it 'is successful' do
              response = strategy.callback(request_body: request_body, parameters: parameters)

              expect(response.success?).to eq(true)
              expect(response.result.class).to eq(Authentication::RoleIdentifier)
              expect(response.result.identifier).to eq(conjur_role_identifier)
              expect(response.result.annotations).to eq({})
            end
            context 'when host includes slashes' do
              let(:params_id) { 'host/foo/bar' }
              let(:conjur_role_identifier) { 'default:host:foo/bar' }

              it 'is successful' do
                response = strategy.callback(request_body: request_body, parameters: parameters)

                expect(response.success?).to eq(true)
                expect(response.result.class).to eq(Authentication::RoleIdentifier)
                expect(response.result.identifier).to eq(conjur_role_identifier)
                expect(response.result.annotations).to eq({})
              end
            end
          end
          context 'when provided API key does not match the stored API key' do
            before do
              expect(credential).to receive(:valid_api_key?).with('abc123').and_return(false)
            end
            it 'is unsuccessful' do
              response = strategy.callback(request_body: request_body, parameters: parameters)

              expect(response.success?).to eq(false)
              expect(response.message.class).to eq(Authentication::RoleIdentifier)
              expect(response.message.identifier).to eq(conjur_role_identifier)
              expect(response.message.annotations).to eq({})
              expect(response.status).to eq(:unauthorized)
              expect(response.exception.class).to eq(Errors::Conjur::ApiKeyNotFound)
            end
          end
        end
        context 'When Credential is not found' do
          before do
            expect(credentials).to receive(:[]).with(conjur_role_identifier).and_return(nil)
          end

          it 'is unsuccessful' do
            response = strategy.callback(request_body: request_body, parameters: parameters)

            expect(response.success?).to eq(false)
            expect(response.message.class).to eq(Authentication::RoleIdentifier)
            expect(response.message.identifier).to eq(conjur_role_identifier)
            expect(response.message.annotations).to eq({})
            expect(response.status).to eq(:unauthorized)
            expect(response.exception.class).to eq(Errors::Authentication::RoleHasNoCredentials)
          end
        end
      end
      context 'when Role is not found' do
        before do
          expect(role).to receive(:[]).with(conjur_role_identifier).and_return(nil)
        end

        it 'is unsuccessful' do
          response = strategy.callback(request_body: request_body, parameters: parameters)

          expect(response.success?).to eq(false)
          expect(response.message.class).to eq(Authentication::RoleIdentifier)
          expect(response.message.identifier).to eq(conjur_role_identifier)
          expect(response.message.annotations).to eq({})
          expect(response.status).to eq(:unauthorized)
          expect(response.exception.class).to eq(Errors::Authentication::Security::RoleNotFound)
        end
      end
    end
  end
end
