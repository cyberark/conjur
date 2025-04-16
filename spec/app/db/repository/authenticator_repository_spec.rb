# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(DB::Repository::AuthenticatorRepository) do
  let(:repo) do
    described_class.new
  end
  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  let(:services) { %w[foo bar] }

  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')
  end

  let(:variables) { {} }

  let(:authenticators) do
    [
      { 
        type: "oidc",
        branch: "conjur/authn-oidc",
        name: "bar",
        enabled: true,
        annotations: { "test" => "bar" },
        owner: { id: "admin", kind: "user" },
        data: variables 
      },
      { 
        type: "oidc",
        name: "foo",
        branch: "conjur/authn-oidc",
        enabled: true,
        annotations: { "test" => "foo" },
        owner: { id: "admin", kind: "user" },
        data: variables 
      }
    ]
  end

  let(:arguments) { %i[provider_uri client_id client_secret claim_mapping] }

  describe('#find_all') do
    context 'when webservice is not present' do
      it 'is unsuccessful' do
        response = repo.find_all_if_visible(type: 'authn-oidc', role: current_user, account: 'rspec')

        expect(response.success?).to be(true)
        expect(response.result).to eq([])
      end
    end

    context 'when webservices are presents' do
      before(:each) do
        services.each do |service|
          ::Role.create(
            role_id: "rspec:policy:conjur/authn-oidc/#{service}"
          )

          # Webservice for authenticator

          ::Annotation.create(
            resource: ::Resource.create(
              resource_id: "rspec:webservice:conjur/authn-oidc/#{service}",
              owner_id: 'rspec:user:admin'
            ),
            name: "test",
            value: service.to_s
          )

          ::AuthenticatorConfig.create(
            resource_id: "rspec:webservice:conjur/authn-oidc/#{service}",
            enabled: "true"
          )
          # Webservice for authenticator status
          ::Resource.create(
            resource_id: "rspec:webservice:conjur/authn-oidc/#{service}/status",
            owner_id: 'rspec:user:admin'
          )
        end
      end

      context 'Type is not set' do
        before(:each) do
          # Webservice for authenticator
          ::Resource.create(
            resource_id: "rspec:webservice:conjur/authn-jwt/baz",
            owner_id: 'rspec:user:admin'
          )
          ::Resource.create(
            resource_id: "rspec:webservice:conjur/app/testapp",
            owner_id: 'rspec:user:admin'
          )
          # Webservice for authenticator status
          ::Resource.create(
            resource_id: "rspec:webservice:conjur/authn-jwt/baz/status",
            owner_id: 'rspec:user:admin'
          )
        end

        it 'returns the relevant variable data' do
          response = repo.find_all_if_visible(type: nil, role: current_user, account: 'rspec')
          authns = authenticators.insert(0, { 
            type: "jwt",
            branch: "conjur/authn-jwt",
            name: "baz",
            enabled: false,
            owner: { id: "admin", kind: "user" },
            data: {} 
          })

          expect(response.success?).to be(true)
          expect(response.result.map(&:to_h)).to eq(authns)
        end
        after(:each) do
          ::Resource["rspec:webservice:conjur/authn-jwt/baz"].destroy
          ::Resource["rspec:webservice:conjur/app/testapp"].destroy
          ::Resource["rspec:webservice:conjur/authn-jwt/baz/status"].destroy
        end
      end

      context 'variables are not loaded' do
        it 'returns the identified authenticator accounts and service-ids' do
          response = repo.find_all_if_visible(type: 'authn-oidc', role: current_user, account: 'rspec')
      
          expect(response.success?).to be(true)
          expect(response.result.map(&:to_h)).to eq(authenticators)
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

        let(:variables)  do 
          {
            claim_mapping: "",
            client_id: "",
            client_secret: "",
            provider_uri: ""
          } 
        end

        context 'secrets are not set' do
          it 'items are returned with values set to empty strings' do
            response = repo.find_all_if_visible(type: 'authn-oidc', role: current_user, account: 'rspec')
            expect(response.success?).to be(true)
            expect(response.result.map(&:to_h)).to eq(authenticators)
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

          let(:variables) { { claim_mapping: 'claim_mapping', client_id: 'client_id', client_secret: 'client_secret', provider_uri: 'provider_uri' } }

          it 'returns the relevant variable data' do
            response = repo.find_all_if_visible(type: 'authn-oidc', role: current_user, account: 'rspec')

            expect(response.success?).to be(true)
            expect(response.result.map(&:to_h)).to eq(authenticators)
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
