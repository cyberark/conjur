# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(DB::Repository::AuthenticatorRepository) do
  let(:repo) do
    described_class.new
  end

  let(:arguments) { %i[provider_uri client_id client_secret claim_mapping] }

  describe('#find_all') do
    context 'when webservice is not present' do
      it 'is unsuccessful' do
        response = repo.find_all(type: 'authn-oidc', account: 'rspec')

        expect(response.success?).to be(false)
        expect(response.message).to eq("Failed to find any authenticators for 'authn-oidc' in account: 'rspec'")
      end
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
        it 'returns the identified authenticator accounts and service-ids' do
          response = repo.find_all(type: 'authn-oidc', account: 'rspec')

          expect(response.success?).to be(true)
          expect(response.result).to eq([
            { account: 'rspec', service_id: 'bar' },
            { account: 'rspec', service_id: 'foo' }
          ])
        end
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
          it 'items are returned with values set to empty strings' do
            empty_hash = { account: 'rspec', claim_mapping: '', client_id: '', client_secret: '', provider_uri: '' }

            response = repo.find_all(type: 'authn-oidc', account: 'rspec')

            expect(response.success?).to be(true)
            expect(response.result).to eq([
              empty_hash.merge(service_id: 'bar'),
              empty_hash.merge(service_id: 'foo')
            ])
          end
        end

        context 'secrets are set' do
          before(:each) do
            services.each do |service|
              arguments.each do |variable|
                ::Secret.create(
                  resource_id: "rspec:variable:conjur/authn-oidc/#{service}/#{variable}",
                  value: variable.to_s
                )
              end
            end
          end

          it 'returns the relevant variable data' do
            expected_values = { account: 'rspec', claim_mapping: 'claim_mapping', client_id: 'client_id', client_secret: 'client_secret', provider_uri: 'provider_uri' }
            response = repo.find_all(type: 'authn-oidc', account: 'rspec')

            expect(response.success?).to be(true)
            expect(response.result).to eq([
              expected_values.merge(service_id: 'bar'),
              expected_values.merge(service_id: 'foo')
            ])
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
      it 'is unsuccessful' do
        response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')

        expect(response.success?).to be(false)
        expect(response.exception.class).to be(Errors::Authentication::Security::WebserviceNotFound)
        expect(response.status).to eq(:unauthorized)
      end
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
        it 'returns the minimum available data' do
          response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')

          expect(response.success?).to be(true)
          expect(response.result).to eq({ account: 'rspec', service_id: 'abc123' })
        end
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

        context 'but variables have no values' do
          it 'is returns the variables with empty values' do
            response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')

            expect(response.success?).to be(true)
            expect(response.result).to eq({ account: 'rspec', service_id: 'abc123', claim_mapping: '', client_id: '', client_secret: '', provider_uri: '' })
          end
        end

        context 'variables are set with values' do
          before(:each) do
            arguments.each do |variable|
              ::Secret.create(
                resource_id: "rspec:variable:conjur/authn-oidc/abc123/#{variable}",
                value: variable.to_s
              )
            end
          end

          it 'returns relevant variables and values' do
            response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')

            expect(response.success?).to be(true)
            expect(response.result).to eq({
              account: 'rspec',
              service_id: 'abc123',
              claim_mapping: 'claim_mapping',
              client_id: 'client_id',
              client_secret: 'client_secret',
              provider_uri: 'provider_uri'
            })
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
end
