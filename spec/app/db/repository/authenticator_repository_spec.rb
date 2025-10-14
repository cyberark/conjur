# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(DB::Repository::AuthenticatorRepository) do
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  let(:resource_repository) do
    ::Resource
  end

  let(:auth_type_factory) do
    AuthenticatorsV2::AuthenticatorTypeFactory.new
  end

  let(:repo) do
    described_class.new(
      logger: logger,
      auth_type_factory: auth_type_factory,
      resource_repository: resource_repository
    )
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
        response = repo.find_all(type: 'authn-oidc', account: 'rspec')

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
          response = repo.find_all(type: nil,  account: 'rspec')
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

      context 'when there is a misconfigured authenticator' do
        before(:each) do
          ::Resource.create(
            resource_id: "rspec:webservice:conjur/authn-test/baz",
            owner_id: 'rspec:user:admin'
          )
        end
        it 'returns the relevant variable data' do
          response = repo.find_all(type: nil,  account: 'rspec')

          expect(log_output.string).to include("'authn-test' authenticators are not supported")
          expect(response.success?).to be(true)
          expect(response.result.map(&:to_h)).to eq(authenticators)
        end

        after(:each) do
          ::Resource["rspec:webservice:conjur/authn-test/baz"].destroy
        end
      end

      context 'When there is an error retriving authenticator variables' do
        let(:auth_facotory) do
          instance_double(AuthenticatorsV2::AuthenticatorTypeFactory).tap do |double|
            allow(double).to receive(:call).and_raise("test error")
          end
        end

        let(:repo) do
          ::DB::Repository::AuthenticatorRepository.new(
            logger: logger,
            auth_type_factory: auth_facotory
          )
        end

        context 'when type is set' do
          it 'logs an error' do
            response = repo.find_all(type: 'authn-oidc', account: 'rspec')
            expect(log_output.string).to include("failed to load 'authn-oidc' authenticator 'bar'")
            expect(response.success?).to be(true)
            expect(response.result).to eq([])
          end
        end
        context 'when type is not set' do
          it 'logs an error' do
            response = repo.find_all(account: 'rspec')
            expect(log_output.string).to include("failed to load authenticator 'bar'")
            expect(response.success?).to be(true)
            expect(response.result).to eq([])
          end
        end
      end

      context 'variables are not loaded' do
        it 'returns the identified authenticator accounts and service-ids' do
          response = repo.find_all(type: 'authn-oidc',  account: 'rspec')
      
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
            response = repo.find_all(type: 'authn-oidc',  account: 'rspec')
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
            response = repo.find_all(type: 'authn-oidc',  account: 'rspec')

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

  describe('#count_all') do
    context 'when counting all authenticators' do
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

      it 'uses default repository when not provided' do
        result = repo.count_all(
          account: 'rspec',
          type: nil
        )
        expect(result).to eq(2)
      end

      it 'respects type filtering' do
        result = repo.count_all(
          account: 'rspec',
          type: 'authn-jwt'
        )
        expect(result).to eq(0)
      end

      context "When Resource model has an offself and limit" do
        let(:resource_repository) do
          ::Resource.limit(1).offset(20)
        end
        it 'ignores offset and limit parameters' do
          result = repo.count_all(
            account: 'rspec',
            type: nil
          )
          expect(result).to eq(2)
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
    let(:authenticator) { {} }
    context 'when webservice is not present' do
      it 'is unsuccessful' do
        response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')

        expect(response.success?).to be(false)
        expect(response.exception.class).to be(Errors::Authentication::Security::WebserviceNotFound)
        expect(response.status).to eq(:not_found)
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

      let(:authenticator) do
        {
          type: "oidc",
          branch: "conjur/authn-oidc",
          name: "abc123",
          enabled: false,
          owner: { id: "conjur/authn-oidc/abc123", kind: "policy" },
          data: variables 
        }
      end

      context 'when no variables are set' do
        it 'returns the minimum available data' do
          response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')

          expect(response.success?).to be(true)
          expect(response.result.to_h).to eq(authenticator)
        end
      end

      context 'when all variables are present' do
        let(:variables)  do 
          {
            claim_mapping: "",
            client_id: "",
            client_secret: "",
            provider_uri: ""
          } 
        end
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
            expect(response.result.to_h).to eq(authenticator)
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

          let(:variables) { { claim_mapping: 'claim_mapping', client_id: 'client_id', client_secret: 'client_secret', provider_uri: 'provider_uri' } }

          it 'returns relevant variables and values' do
            response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')
            expect(response.success?).to be(true)
            expect(response.result.to_h).to eq(authenticator)
          end
        end

        context 'Resource Returns an error' do
          before do
            allow(resource_repository).to receive(:where)
              .and_raise("repo error")
          end
      
          it 'returns failure and log messsage' do
            response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')
            expect(log_output.string).to include("failed to load 'authn-oidc' authenticator 'abc123' due to: repo error")
            expect(response.success?).to be(false)
            expect(response.status).to be(:unauthorized)
          end
        end

        context 'auth_type_factory Returns an error' do
          before do
            allow(auth_type_factory).to receive(:call)
              .and_raise("repo error")
          end
      
          it 'returns failure and log messsage' do
            response = repo.find(type: 'authn-oidc', account: 'rspec', service_id: 'abc123')
            expect(log_output.string).to include("failed to load 'authn-oidc' authenticator 'abc123' due to: repo error")
            expect(response.success?).to be(false)
            expect(response.status).to be(:unauthorized)
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

  describe '#delete' do
    let(:owner_id) { "rspec:user:my_admin" }
    let(:policy_id) { "rspec:policy:data" }
    let(:resource_id) { "rspec:host:data/workload" }
    let(:secret_id) { "rspec:variable:data/secret" }

    let(:role) { Role.create(role_id: owner_id) }
    let(:resource) { Resource.create(resource_id: resource_id, owner_id: role.id) }
    let(:secret) { Resource.create(resource_id: secret_id, owner_id: role.id) }

    before do
      allow(resource_repository).to receive(:[])
        .with(resource_id: resource_id)
        .and_return(resource)
      allow(resource_repository).to receive(:[])
        .with(resource_id: secret_id)
        .and_return(secret)
    end

    context("when more than 1 resource exists") do
      before do
        allow(::Role).to receive(:[])
          .with(resource_id)
          .and_return(nil)
        allow(::Role).to receive(:[])
          .with(secret_id)
          .and_return(nil)
        allow(resource).to receive(:destroy)
        allow(secret).to receive(:destroy)
        allow(::Resource).to receive(:where).with(owner_id: resource_id).and_return([secret])
        allow(::Resource).to receive(:where).with(owner_id: secret_id).and_return([])
      end

      it "deletes all owned resources and roles recursively" do
        expect(::Resource).to receive(:where).with(owner_id: resource_id)
        expect(::Resource).to receive(:where).with(owner_id: secret_id)
        expect(resource).to receive(:destroy)
        expect(secret).to receive(:destroy)
        expect(repo.delete(policy_id: resource_id)).not_to(be_nil)
      end
    end

    context("When the resource is protected") do
      let(:resource_id) { "rspec:policy:conjur/authn-gcp" }
      before do
        allow(::Resource).to receive(:where).with(owner_id: resource_id).and_return([secret])
        allow(::Resource).to receive(:where).with(owner_id: secret_id).and_return([])
      end

      it "doesn't delete the protected resources" do
        expect(::Resource).to receive(:where).with(owner_id: resource_id)
        expect(::Resource).to receive(:where).with(owner_id: secret_id)
        expect(resource).not_to receive(:destroy)
        expect(secret).to receive(:destroy)
        expect(repo.delete(policy_id: resource_id)).not_to(be_nil)
      end
    end

    context("when resource and role exist") do
      let(:resource_role) { Role.create(role_id: resource.id) }

      before do
        allow(resource_role).to receive(:destroy)
        allow(::Resource).to(receive(:where).with(owner_id: resource_id).and_return([]))
        allow(::Role).to receive(:[])
          .with(resource_id)
          .and_return(resource_role)
      end

      it "deletes all owned resources and roles recursively" do
        expect(::Resource).to receive(:where).with(owner_id: resource_id)
        expect(resource).to receive(:destroy)
        expect(resource_role).to receive(:destroy)
        expect(repo.delete(policy_id: resource_id)).not_to be_nil
      end
    end

    context("when the resource doesn't own anything") do
      before do
        allow(resource_repository).to receive(:[])
          .with(resource_id: resource_id)
          .and_return(resource)
        allow(::Resource).to receive(:where)
          .with(owner_id: resource_id)
          .and_return([])
      end

      it "returns nil" do
        expect(resource).to receive(:destroy)
        expect(repo.delete(policy_id: resource_id)).not_to be_nil
      end
    end
  end

  # Test infinite loop
  describe '#delete' do
    context 'When one resource is its own owner' do
      before(:each) do
        # Webservice for authenticator
        ::Role.create(
          role_id: "rspec:webservice:conjur/authn-jwt/baz"
        )
        ::Role.create(
          role_id: "rspec:group:conjur/app/testapp"
        )
        ::Resource.create(
          resource_id: "rspec:webservice:conjur/authn-jwt/baz",
          owner_id: "rspec:webservice:conjur/authn-jwt/baz"
        )
        ::Resource.create(
          resource_id: "rspec:group:conjur/app/testapp",
          owner_id: "rspec:webservice:conjur/authn-jwt/baz"
        )
        # Webservice for authenticator status
        ::Resource.create(
          resource_id: "rspec:webservice:conjur/authn-jwt/baz/status",
          owner_id: "rspec:webservice:conjur/authn-jwt/baz"
        )

        ::Resource.create(
          resource_id: "rspec:variable:conjur/authn-jwt/baz/stuff",
          owner_id: "rspec:group:conjur/app/testapp"
        )
      end

      it 'deletes the resources' do
        response = repo.delete(policy_id: "rspec:webservice:conjur/authn-jwt/baz")
        expect(response.resource_id).to eq("rspec:webservice:conjur/authn-jwt/baz")
      end
      after(:each) do
        expect(::Role["rspec:webservice:conjur/authn-jwt/baz"]).to be_nil
        expect(::Role["rspec:group:conjur/app/testapp"]).to be_nil
        expect(::Resource["rspec:webservice:conjur/authn-jwt/baz/stuff"]).to be_nil
        expect(::Resource["rspec:webservice:conjur/authn-jwt/baz"]).to be_nil
        expect(::Resource["rspec:group:conjur/app/testapp"]).to be_nil
        expect(::Resource["rspec:webservice:conjur/authn-jwt/baz/status"]).to be_nil
      end
    end
  end
end
