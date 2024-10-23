# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::CommandHandlers::Authentication) do
  let(:namespace_selector) do
    class_double(Authentication::Util::NamespaceSelector).tap do |double|
      allow(double).to receive(:type_to_module).with(authenticator_type).and_return(authenticator_module)
    end
  end
  let(:authenticator_module) { authenticator_type.underscore.camelcase }
  let(:klass_loader_class) do
    class_double(Authentication::Util::V2::KlassLoader).tap do |double|
      allow(double).to receive(:new).with(authenticator_type).and_return(
        Authentication::Util::V2::KlassLoader.new(authenticator_type, namespace_selector: namespace_selector)
      )
    end
  end
  describe('.params_allowed') do
    let(:handler) do
      described_class.new(
        authenticator_type: authenticator_type,
        klass_loader_library: klass_loader_class
      )
    end
    context 'when strategy does not include any `ALLOWED_PARAMS` values' do
      let(:authenticator_type) { 'test-empty' }
      it 'returns the default parameters' do
        response = handler.params_allowed

        expect(response).to eq(%i[authenticator service_id account id])
      end
    end
    context 'when strategy includes `ALLOWED_PARAMS` values' do
      let(:authenticator_type) { 'test' }
      it 'returns the default and allowed parameters' do
        response = handler.params_allowed

        expect(response).to eq(%i[authenticator service_id account id foo bar])
      end
    end
  end
  describe('.call') do
    let(:authenticator_type) { 'test' }
    let(:handler) do
      described_class.new(
        authenticator_type: authenticator_type,
        klass_loader_library: klass_loader_class,
        available_authenticators: available_authenticators
      )
    end
    let(:args) { { request_ip: '127.0.0.1', parameters: { service_id: 'foo', account: 'rspec' }, request_body: '' } }

    context 'when authenticator is not enabled' do
      let(:available_authenticators) do
        class_double(Authentication::InstalledAuthenticators).tap do |double|
          allow(double).to receive(:enabled_authenticators).and_return([])
          allow(double).to receive(:native_authenticators).and_return(['authn'])
        end
      end
      it 'is unsuccessful' do
        response = handler.call(**args)

        expect(response.success?).to be(false)
        expect(response.exception.class).to be(Errors::Authentication::Security::AuthenticatorNotWhitelisted)
        expect(response.exception.message).to eq("CONJ00004E 'test/foo' is not enabled")
        expect(response.status).to eq(:bad_request)
      end
    end

    context 'when authenticator is enabled' do
      let(:token_factory) do
        instance_double(TokenFactory).tap do |double|
          allow(double).to receive(:signed_token).and_return('success-token')
        end
      end
      let(:role) { Role.new(role_id: 'rspec:user:foo-bar') }
      let(:role_resource) do
        class_double(::Role).tap do |double|
          allow(double).to receive(:[]).with('rspec:user:foo-bar').and_return(role)
        end
      end
      let(:available_authenticators) do
        class_double(Authentication::InstalledAuthenticators).tap do |double|
          # rubocop:disable Style/WordArray
          allow(double).to receive(:enabled_authenticators).and_return(['test-empty', 'test/foo', 'test-with-ttl'])
          allow(double).to receive(:native_authenticators).and_return(['test-empty', 'test-with-ttl'])
          # rubocop:enable Style/WordArray
        end
      end
      context 'auth token TTL' do
        let(:host_ttl) { 100 }
        let(:user_ttl) { 200 }

        let(:configuration) { ConjurConfiguration.new(host_ttl, user_ttl) }
        let(:handler) do
          described_class.new(
            authenticator_type: authenticator_type,
            klass_loader_library: klass_loader_class,
            available_authenticators: available_authenticators,
            role_resource: role_resource,
            token_factory: token_factory,
            configuration: configuration
          )
        end

        context 'when authenticator TTL is not defined on the authenticator data object' do
          let(:authenticator_type) { 'test-empty' }
          let(:token_factory) do
            instance_double(TokenFactory).tap do |double|
              allow(double).to receive(:signed_token).with(
                account: 'rspec',
                # file deepcode ignore HardcodedCredential: This is a test code, not an actual credential
                username: 'foo-bar',
                host_ttl: host_ttl,
                user_ttl: user_ttl
              ).and_return('success-token')
            end
          end
          it 'uses the configured TTL' do
            response = handler.call(**args.merge(parameters: { account: 'rspec' }))
            expect(response.success?).to be(true)
            expect(response.result).to eq('success-token')
          end
        end

        context 'when authenticator data object defines the TTL' do
          let(:authenticator_type) { 'test-with-ttl' }
          let(:token_factory) do
            instance_double(TokenFactory).tap do |double|
              allow(double).to receive(:signed_token).with(
                account: 'rspec',
                username: 'foo-bar',
                host_ttl: 180,
                user_ttl: 180
              ).and_return('success-token')
            end
          end

          it 'is successful' do
            response = handler.call(**args.merge(parameters: { account: 'rspec' }))
            expect(response.success?).to be(true)
            expect(response.result).to eq('success-token')
          end
        end
      end
      context 'when authenticator is native' do
        let(:authenticator_type) { 'test-empty' }
        let(:handler) do
          described_class.new(
            authenticator_type: authenticator_type,
            klass_loader_library: klass_loader_class,
            available_authenticators: available_authenticators,
            role_resource: role_resource,
            token_factory: token_factory
          )
        end

        it 'is successful' do
          response = handler.call(**args.merge(parameters: { account: 'rspec' }))
          expect(response.success?).to be(true)
          expect(response.result).to eq('success-token')
        end
      end
      context 'when authenticator has a webservice' do
        let(:authenticator_type) { 'test' }
        let(:handler) do
          described_class.new(
            authenticator_type: 'test',
            klass_loader_library: klass_loader_class,
            available_authenticators: available_authenticators,
            role_resource: role_resource,
            token_factory: token_factory,
            authenticator_repository: authenticator_repository,
            authorization: rbac
          )
        end

        let(:authenticator_repository) do
          instance_double(DB::Repository::AuthenticatorRepository).tap do |double|
            allow(double).to receive(:find).with(type: 'test', account: 'rspec', service_id: 'foo').and_return(SuccessResponse.new({ account: 'rspec', service_id: 'foo' }))
          end
        end

        let(:rbac) do
          instance_double(RBAC::Permission).tap do |double|
            allow(double).to receive(:permitted?).and_return(SuccessResponse.new(role))
          end
        end
        context 'when there are no ip address restrictions on the role' do
          it 'is successful' do
            response = handler.call(**args)

            expect(response.success?).to be(true)
            expect(response.result).to eq('success-token')
          end
        end
        context 'when the role attempts to login from an invalid origin' do
          let(:role) do
            role = Role.new(role_id: 'rspec:user:foo-bar')
            allow(role).to receive(:restricted_to).and_return([Util::CIDR.new('192.0.2.0/24')])
            role
          end
          it 'is unsuccessful' do
            response = handler.call(**args)

            expect(response.success?).to be(false)
            expect(response.exception.class).to eq(Errors::Authentication::InvalidOrigin)
            expect(response.status).to eq(:unauthorized)
          end
        end
        context 'when the role is not found' do
          let(:role) { nil }

          it 'is unsuccessful' do
            response = handler.call(**args)

            expect(response.success?).to be(false)
            expect(response.exception.class).to eq(Errors::Authentication::Security::RoleNotFound)
            expect(response.status).to eq(:bad_request)
          end
        end
      end
    end
  end
end

ConjurConfiguration = Struct.new(:host_authorization_token_ttl, :user_authorization_token_ttl)

module Authentication
  module Test
    module V2
      module DataObjects
        class Authenticator < Authentication::Base::DataObject
          attr_reader(:account, :service_id)

          def initialize(account:, service_id:)
            super(account: account, service_id: service_id)
          end
        end
      end

      class Strategy
        ALLOWED_PARAMS = %i[foo bar].freeze

        def initialize(authenticator:); end

        def callback(*)
          SuccessResponse.new(
            Authentication::RoleIdentifier.new(
              identifier: 'rspec:user:foo-bar'
            )
          )
        end
      end
    end
  end

  module TestEmpty
    module V2
      module DataObjects
        class Authenticator < Authentication::Base::DataObject
          attr_reader(:account)

          def initialize(account:)
            super(account: account)
          end
        end
      end

      class Strategy
        def initialize(authenticator:); end

        def callback(*)
          SuccessResponse.new(
            Authentication::RoleIdentifier.new(
              identifier: 'rspec:user:foo-bar'
            )
          )
        end
      end
    end
  end

  module TestWithTtl
    module V2
      module DataObjects
        class Authenticator < Authentication::Base::DataObject
          attr_reader(:account)

          def initialize(account:)
            super(account: account)
            @token_ttl = 'PT3M'
          end
        end
      end

      class Strategy
        def initialize(authenticator:); end

        def callback(*)
          SuccessResponse.new(
            Authentication::RoleIdentifier.new(
              identifier: 'rspec:user:foo-bar'
            )
          )
        end
      end
    end
  end
end
