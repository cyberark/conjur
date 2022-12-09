# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('DB::Repository::AuthenticatorRepository') do
  let(:resource_repository) { ::Resource }

  let(:repo) do
    DB::Repository::AuthenticatorRepository.new(
      resource_repository: resource_repository,
      data_object: Authentication::AuthnOidc::V2::DataObjects::Authenticator,
      enabled_authenticators: enabled_authenticators
    )
  end

  let (:enabled_authenticators) {
    %w[authn-oidc/foo-abc123
       authn-oidc/baz-abc123
       authn-oidc/bar-abc123]
  }

  let(:arguments) { %i[provider_uri client_id client_secret claim_mapping nonce state] }

  describe('#find_all') do
    context 'when webservice is not present' do
      it { expect(repo.find_all(type: 'authn-oidc', account: 'rspec')).to eq([]) }
    end

    context 'when webservices are presents' do
      let(:services) { %i[foo bar] }
      before(:each) do
        services.each do |service|
          ::Role.create(
            role_id: "rspec:policy:conjur/authn-oidc/#{service}-abc123"
          )
          ::Resource.create(
            resource_id: "rspec:webservice:conjur/authn-oidc/#{service}-abc123",
            owner_id: "rspec:policy:conjur/authn-oidc/#{service}-abc123"
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
                resource_id: "rspec:variable:conjur/authn-oidc/#{service}-abc123/#{variable}",
                owner_id: "rspec:policy:conjur/authn-oidc/#{service}-abc123"
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
                  resource_id: "rspec:variable:conjur/authn-oidc/#{service}-abc123/#{variable}",
                  value: "#{variable}-abc123"
                )
              end
            end
          end

          let(:authenticators) { repo.find_all(type: 'authn-oidc', account: 'rspec') }

          it { expect(authenticators.length).to eq(2) }
          it { expect(authenticators.first).to be_kind_of(Authentication::AuthnOidc::V2::DataObjects::Authenticator) }
          it { expect(authenticators.last).to be_kind_of(Authentication::AuthnOidc::V2::DataObjects::Authenticator) }

          context 'filters invalid authenticators' do
            before(:each) do
              ::Role.create(
                role_id: "rspec:policy:conjur/authn-oidc/baz-abc123"
              )
              ::Resource.create(
                resource_id: "rspec:webservice:conjur/authn-oidc/baz-abc123",
                owner_id: "rspec:policy:conjur/authn-oidc/baz-abc123"
              )
            end

            it { expect(repo.find_all(type: 'authn-oidc', account: 'rspec').length).to eq(2) }

            after(:each) do
              ::Resource['rspec:webservice:conjur/authn-oidc/baz-abc123'].destroy
              ::Role['rspec:policy:conjur/authn-oidc/baz-abc123'].destroy
            end
          end

          context 'when webservices status are presents' do
            before(:each) do
                ::Resource.create(
                  resource_id: "rspec:webservice:conjur/authn-oidc/foo-abc123/status",
                  owner_id: "rspec:policy:conjur/authn-oidc/foo-abc123"
                )
              end

            it { expect(repo.find_all(type: 'authn-oidc', account: 'rspec').length).to eq(2) }

            after(:each) do
              ::Resource['rspec:webservice:conjur/authn-oidc/foo-abc123/status'].destroy
            end
          end
        end

        after(:each) do
          services.each do |service|
            arguments.each do |variable|
              ::Resource["rspec:variable:conjur/authn-oidc/#{service}-abc123/#{variable}"].destroy
            end
          end
        end
      end

      after(:each) do
        services.each do |service|
          ::Resource["rspec:webservice:conjur/authn-oidc/#{service}-abc123"].destroy
          ::Role["rspec:policy:conjur/authn-oidc/#{service}-abc123"].destroy
        end
      end

    end
  end

  describe('#find') do
    context 'when webservice is not present' do
      it { expect(repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')).to be(nil) }
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
                value: "#{variable}-abc123"
              )
            end
          end

          let(:authenticator) { repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123') }

          it { expect(authenticator).to be_truthy }
          it { expect(authenticator).to be_kind_of(Authentication::AuthnOidc::V2::DataObjects::Authenticator) }
          it { expect(authenticator.account).to eq('rspec') }
          it { expect(authenticator.service_id).to eq('abc123') }
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
