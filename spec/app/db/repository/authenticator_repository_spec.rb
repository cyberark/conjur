# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('DB::Repository::AuthenticatorRepository') do
  let(:data_object) { Authentication::AuthnOidc::V2::DataObjects::Authenticator }
  let(:resource_repository) { ::Resource }

  let(:repo) do
    DB::Repository::AuthenticatorRepository.new(
      resource_repository: resource_repository,
      data_object: data_object
    )
  end

  let(:arguments) { %i[provider_uri client_id client_secret claim_mapping nonce state] }

  describe('#find_all') do
    context 'when webservice is not present' do
      it { expect(repo.find_all(type: 'authn-oidc', account: 'rspec')).to eq([]) }
    end

    context 'when webservices are presents' do
      let(:services) { %w[foo bar] }
      before(:each) do
        services.each do |service|
          ::Role.create(
            role_id: "rspec:policy:conjur/authn-oidc/#{service}"
          )
          # Webservice for authenticator
          ::Resource.create(
            resource_id: "rspec:webservice:conjur/authn-oidc/#{service}",
            owner_id: "rspec:policy:conjur/authn-oidc/#{service}"
          )
          # Webservice for authenticator status
          ::Resource.create(
            resource_id: "rspec:webservice:conjur/authn-oidc/#{service}/status",
            owner_id: "rspec:policy:conjur/authn-oidc/#{service}"
          )
        end
      end

      let(:resource_repository) { ::Resource }

      let(:repo) do
        DB::Repository::AuthenticatorRepository.new(
          resource_repository: resource_repository,
          data_object: data_object,
          pkce_support_enabled: pkce_flag_enabled
        )
      end

      let(:arguments) { %i[provider_uri client_id client_secret claim_mapping nonce state] }

      describe('#find_all') do
        context 'when webservice is not present' do
          it { expect(repo.find_all(type: 'authn-oidc', account: 'rspec')).to eq([]) }
        end

        context 'when webservices are presents' do
          let(:services) { %w[foo bar] }
          before(:each) do
            services.each do |service|
              ::Role.create(
                role_id: "rspec:policy:conjur/authn-oidc/#{service}"
              )
              # Webservice for authenticator
              ::Resource.create(
                resource_id: "rspec:webservice:conjur/authn-oidc/#{service}",
                owner_id: "rspec:policy:conjur/authn-oidc/#{service}"
              )
              # Webservice for authenticator status
              ::Resource.create(
                resource_id: "rspec:webservice:conjur/authn-oidc/#{service}/status",
                owner_id: "rspec:policy:conjur/authn-oidc/#{service}"
              )
            end
          end

          context 'variables are not loaded' do
            it { expect(repo.find_all(type: 'authn-oidc', account: 'rspec')).to eq([]) }
          end

          context 'variables are loaded' do
            before(:each) do
              services.each do |service|
                arguments.each do |variable|
                  ::Resource.create(
                    resource_id: "rspec:variable:conjur/authn-oidc/#{service}/#{variable}",
                    owner_id: "rspec:policy:conjur/authn-oidc/#{service}"
                  )
                end
              end
            end

            context 'secrets are not set' do
              it { expect(repo.find_all(type: 'authn-oidc', account: 'rspec')).to eq([]) }
            end

            context 'secrets are set' do
              before(:each) do
                services.each do |service|
                  arguments.each do |variable|
                    ::Secret.create(
                      resource_id: "rspec:variable:conjur/authn-oidc/#{service}/#{variable}",
                      value: "#{variable}"
                    )
                  end
                end
              end

              let(:authenticators) { repo.find_all(type: 'authn-oidc', account: 'rspec') }

              it { expect(authenticators.length).to eq(2) }
              it { expect(authenticators.first).to be_kind_of(data_object) }
              it { expect(authenticators.last).to be_kind_of(data_object) }

              context 'filters invalid authenticators' do
                before(:each) do
                  ::Role.create(
                    role_id: "rspec:policy:conjur/authn-oidc/baz"
                  )
                  ::Resource.create(
                    resource_id: "rspec:webservice:conjur/authn-oidc/baz",
                    owner_id: "rspec:policy:conjur/authn-oidc/baz"
                  )
                end

                it { expect(repo.find_all(type: 'authn-oidc', account: 'rspec').length).to eq(2) }

                after(:each) do
                  ::Resource['rspec:webservice:conjur/authn-oidc/baz'].destroy
                  ::Role['rspec:policy:conjur/authn-oidc/baz'].destroy
                end
              end
            end

            after(:each) do
              services.each do |service|
                arguments.each do |variable|
                  ::Resource["rspec:variable:conjur/authn-oidc/#{service}/#{variable}"].destroy
                end
              end
            end
          end

          after(:each) do
            services.each do |service|
              ::Resource["rspec:webservice:conjur/authn-oidc/#{service}"].destroy
              ::Role["rspec:policy:conjur/authn-oidc/#{service}"].destroy
            end
          end
        end
      end

      describe('#find') do
        context 'when webservice is not present' do
          it { expect {
            repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')
          }.to raise_exception(
              Errors::Authentication::Security::WebserviceNotFound
            )
          }
        end

        context 'when webservice is present' do
          before(:each) do
            ::Role.create(
              role_id: "rspec:policy:conjur/authn-oidc/abc123"
            )
            ::Resource.create(
              resource_id: "rspec:webservice:conjur/authn-oidc/abc123",
              owner_id: "rspec:policy:conjur/authn-oidc/abc123"
            )
          end

          context 'when no variables are set' do
            it { expect(repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')).to be(nil) }
          end

          context 'when all variables are present' do
            before(:each) do
              arguments.each do |variable|
                ::Resource.create(
                  resource_id: "rspec:variable:conjur/authn-oidc/abc123/#{variable}",
                  owner_id: "rspec:policy:conjur/authn-oidc/abc123"
                )
              end
            end

            context 'are empty' do
              it { expect(repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')).to be(nil) }
            end

            context 'are set' do
              before(:each) do
                arguments.each do |variable|
                  ::Secret.create(
                    resource_id: "rspec:variable:conjur/authn-oidc/abc123/#{variable}",
                    value: "#{variable}"
                  )
                end
              end

              let(:authenticator) { repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123') }

              it { expect(authenticator).to be_truthy }
              it { expect(authenticator).to be_kind_of(data_object) }
              it { expect(authenticator.account).to eq('rspec') }
              it { expect(authenticator.service_id).to eq('abc123') }

              context 'custom token TTL' do
                before(:each) do
                  ::Resource.create(
                    resource_id: "rspec:variable:conjur/authn-oidc/abc123/token_ttl",
                    owner_id: "rspec:policy:conjur/authn-oidc/abc123"
                  )
                  ::Secret.create(
                    resource_id: "rspec:variable:conjur/authn-oidc/abc123/token_ttl",
                    value: "PT2H"
                  )
                end

                it { expect(authenticator.token_ttl).to eq(2.hours) }
              end
            end

            after(:each) do
              arguments.each do |variable|
                ::Resource["rspec:variable:conjur/authn-oidc/abc123/#{variable}"].destroy
              end
            end
          end

          after(:each) do
            ::Resource['rspec:webservice:conjur/authn-oidc/abc123'].destroy
            ::Role['rspec:policy:conjur/authn-oidc/abc123'].destroy
          end
        end
      end

      describe('#exists?') do
        context 'when webservice is present' do
          before(:context) do
            ::Role.create(
              role_id: "rspec:policy:conjur/authn-oidc/abc123"
            )
            ::Resource.create(
              resource_id: "rspec:webservice:conjur/authn-oidc/abc123",
              owner_id: "rspec:policy:conjur/authn-oidc/abc123"
            )
          end

          it { expect(repo.exists?(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')).to be_truthy }
          it { expect(repo.exists?(type: nil, account: 'rspec', service_id: 'abc123')).to be_falsey }
          it { expect(repo.exists?(type: 'authn-oidc', account: nil, service_id: 'abc123')).to be_falsey }
          it { expect(repo.exists?(type: 'authn-oidc', account: 'rspec', service_id: nil)).to be_falsey }

          after(:context) do
            ::Resource['rspec:webservice:conjur/authn-oidc/abc123'].destroy
            ::Role['rspec:policy:conjur/authn-oidc/abc123'].destroy
          end
        end

        context 'when webservice is not present' do
          it { expect(repo.exists?(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')).to be_falsey }
          it { expect(repo.exists?(type: nil, account: 'rspec', service_id: 'abc123')).to be_falsey }
          it { expect(repo.exists?(type: 'authn-oidc', account: nil, service_id: 'abc123')).to be_falsey }
          it { expect(repo.exists?(type: 'authn-oidc', account: 'rspec', service_id: nil)).to be_falsey }
        end
      end
    end
  end
end
