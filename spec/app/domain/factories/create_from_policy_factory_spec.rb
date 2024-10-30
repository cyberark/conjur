# frozen_string_literal: true

require 'spec_helper'
require 'policy_factory_helper'

RSpec.describe(Factories::CreateFromPolicyFactory) do
  let(:default_policy_args) do
    {
      loader: Loader::CreatePolicy,
      request_type: 'POST',
      context: context,
      policy: "- !user\n  id: foo\n  annotations:\n    factory: core/v1/user\n",
      target_policy_id: "rspec:policy:bar"
    }
  end
  let(:policy_response) { SuccessResponse.new('success') }
  let(:policy_loader) do
    spy(CommandHandler::Policy).tap do |double|
      allow(double).to receive(:call).and_return(policy_response)
    end
  end
  let(:secrets_response) { SuccessResponse.new('success')}
  let(:secrets_repository) do
    spy(DB::Repository::SecretsRepository).tap do |double|
      allow(double).to receive(:update).and_return(secrets_response)
    end
  end
  let(:base) do
    Factories::Base.new(
      policy_loader: policy_loader,
      secrets_repository: secrets_repository
    )
  end
  let(:request_method) { 'POST' }
  let(:context) { RequestContext::Context.new(role: double(::Role), request_ip: '127.0.0.1') }

  subject do
    Factories::CreateFromPolicyFactory
      .new(base)
      .call(
        factory_template: factory_template,
        request_body: request,
        account: 'rspec',
        context: context,
        request_method: request_method
      )
  end

  describe('.call') do
    context 'when using a simple factory' do
      let(:user_factory) do
        # rubocop:disable Layout/HeredocIndentation
        policy = <<~POLICY
        - !user
          id: {{ id }}
        {{#owner_role}}
          {{#owner_type}}
          owner: !{{ owner_type }} {{ owner_role }}
          {{/owner_type}}
        {{/owner_role}}
        {{#ip_range}}
          restricted_to: {{ ip_range }}
        {{/ip_range}}
          annotations:
          {{#annotations}}
            {{ key }}: {{ value }}
          {{/annotations}}
        POLICY
        # rubocop:enable Layout/HeredocIndentation
        # rubocop:disable Layout/LineLength
        Testing::Factories::FactoryBuilder.build(
          version: 'v1',
          schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"User Template","description":"Creates a Conjur User","type":"object","properties":{"id":{"description":"User ID","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this resource into","type":"string"},"owner_role":{"description":"The Conjur Role that will own this user","type":"string"},"owner_type":{"description":"The resource type of the owner of this user","type":"string"},"ip_range":{"description":"Limits the network range the user is allowed to authenticate from","type":"string"}},"required":["branch","id"]}',
          policy: policy,
          policy_branch: '{{ branch }}'
        )
      end
      # rubocop:enable Layout/LineLength
      let(:factory_template) do
        DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
          encoded_factory: user_factory,
          classification: 'core',
          version: 'v1',
          id: 'user'
        ).result
      end
      context 'when request is invalid' do
        context 'when request body is missing' do
          let(:request) { nil }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is empty' do
          let(:request) { '' }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is malformed JSON' do
          let(:request) { '{"foo": "bar }' }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be valid JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is missing keys' do
          let(:request) { { id: 'foo' }.to_json }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "A value is required for 'branch'", key: 'branch' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is missing values' do
          let(:request) { { id: '', branch: 'foo' }.to_json }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "A value is required for 'id'", key: 'id' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when the request body includes invalid values' do
          let(:request) { { id: 'foo%', branch: 'b@r' }.to_json }
          let(:policy_handler_args) { { target_policy_id: "rspec:policy:br" } }
          it 'submits the expected policy to Conjur with invalid characters removed' do
            expect(subject.success?).to be(true)
            expect(policy_loader).to have_received(:call).with(
              default_policy_args.merge(target_policy_id: 'rspec:policy:br')
            )
          end
        end
        let(:grant_factory) do
          # rubocop:disable Layout/HeredocIndentation
          policy = <<~POLICY
          - !grant
            member: !{{ member_resource_type }} {{ member_resource_id }}
            role: !{{ role_resource_type }} {{ role_resource_id }}
          POLICY
          # rubocop:enable Layout/HeredocIndentation
          # rubocop:disable Layout/LineLength
          Testing::Factories::FactoryBuilder.build(
            version: 'v1',
            schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"Grant Template","description":"Assigns a Role to another Role","type":"object","properties":{"id":{"description":"Resource Identifier","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this grant into","type":"string"},"member_resource_type":{"description":"The member type (group, host, user, or layer) for the grant","type":"string","enum":["group","host","user","layer"]},"member_resource_id":{"description":"The member resource identifier for the grant","type":"string"},"role_resource_type":{"description":"The role type (group or layer) for the grant","type":"string","default":"group","enum":["group","layer"]},"role_resource_id":{"description":"The role resource identifier for the grant","type":"string"}},"required":["branch","member_resource_type","member_resource_id","role_resource_type","role_resource_id"]}',
            policy: policy,
            policy_branch: '{{ branch }}'
          )
          # rubocop:enable Layout/LineLength
        end
        context 'when the request body includes a value from the enumeration' do
          context 'when the factory includes variables with default values' do
            let(:factory_template) do
              DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
                encoded_factory: grant_factory,
                classification: 'core',
                version: 'v1',
                id: 'grant'
              ).result
            end
            context 'when the request body includes a value for the default' do
              let(:request) do
                {
                  branch: 'bar',
                  member_resource_type: 'group',
                  member_resource_id: 'foo',
                  role_resource_type: 'layer',
                  role_resource_id: 'bar'
                }.to_json
              end
              it 'submits the policy with the provided values' do
                expect(subject.success?).to be(true)
                expect(policy_loader).to have_received(:call).with(
                  default_policy_args.merge(target_policy_id: 'rspec:policy:bar', policy: "- !grant\n  member: !group foo\n  role: !layer bar\n")
                )
              end
            end
            context 'when the request body does not include a value for an input with a default' do
              let(:request) do
                {
                  branch: 'bar',
                  member_resource_type: 'group',
                  member_resource_id: 'foo',
                  role_resource_id: 'bar'
                }.to_json
              end
              it 'submits the policy with the provided values' do
                expect(subject.success?).to be(true)
                expect(policy_loader).to have_received(:call).with(
                  default_policy_args.merge(
                    target_policy_id: 'rspec:policy:bar',
                    policy: "- !grant\n  member: !group foo\n  role: !group bar\n"
                  )
                )
              end
            end
          end
        end
        context 'when the request body does not include a value from the enumeration' do
          let(:factory_template) do
            DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
              encoded_factory: grant_factory,
              classification: 'core',
              version: 'v1',
              id: 'grant'
            ).result
          end
          let(:request) do
            {
              branch: 'bar',
              member_resource_type: 'baz',
              member_resource_id: 'foo',
              role_resource_type: 'layer',
              role_resource_id: 'bar'
            }.to_json
          end
          it 'returns an error response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Value must be one of: 'group', 'host', 'user', 'layer'", key: 'member_resource_type' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when the request body includes a values with a comma' do
          # rubocop:disable Layout/LineLength
          let(:permit_factory) do
            # rubocop:disable Layout/HeredocIndentation
            policy = <<~POLICY
            - !permit
              role: !{{ role_type }} {{ role_id }}
              resource: !{{ resource_type }} {{ resource_id }}
              privileges: [{{ privileges }}]
            POLICY
            # rubocop:enable Layout/HeredocIndentation
            Testing::Factories::FactoryBuilder.build(
              version: 'v1',
              schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"Permit Template","description":"Assigns permissions to a Role","type":"object","properties":{"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this permit into","type":"string"},"role_type":{"description":"The role type to grant permission on a resource","type":"string","enum":["group","host","layer","policy","user"]},"role_id":{"description":"The role identifier to grant permission on a resource","type":"string"},"resource_type":{"description":"The resource type to grant the permission on","type":"string","enum":["group","host","layer","policy","user","variable"]},"resource_id":{"description":"The resource identifier to grant the permission on","type":"string"},"privileges":{"description":"Comma seperated list of privileges to grant on the resource","type":"string"}},"required":["branch","role_type","role_id","resource_type","resource_id","privileges"]}',
              policy: policy,
              policy_branch: '{{ branch }}'
            )
          end

          # rubocop:enable Layout/LineLength
          let(:factory_template) do
            DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
              encoded_factory: permit_factory,
              classification: 'core',
              version: 'v1',
              id: 'permit'
            ).result
          end
          let(:request) do
            {
              branch: 'foo-bar',
              resource_type: 'variable',
              resource_id: 'foo',
              role_type: 'layer',
              role_id: 'bar',
              privileges: 'read, write'
            }.to_json
          end
          it 'submits the policy with the provided values' do
            expect(subject.success?).to be(true)
            expect(policy_loader).to have_received(:call).with(
              default_policy_args.merge(
                target_policy_id: 'rspec:policy:foo-bar',
                policy: "- !permit\n  role: !layer bar\n  resource: !variable foo\n  privileges: [read,write]\n"
              )
            )
          end
        end
      end
      context 'when request body is valid' do
        let(:request) { { id: 'foo', branch: 'bar' }.to_json }
        it 'submits the expected policy to Conjur' do
          expect(subject.success?).to be(true)
          expect(policy_loader).to have_received(:call).with(default_policy_args)
        end
        context 'when inputs include a hash (ex. for annotations)' do
          let(:request) { { id: 'foo', branch: 'bar', annotations: { 'foo' => 'bar', 'bing' => 'bang' } }.to_json }
          it 'submits the expected policy to Conjur' do
            expect(subject.success?).to be(true)
            expect(policy_loader).to have_received(:call).with(
              default_policy_args.merge(
                policy: "- !user\n  id: foo\n  annotations:\n    foo: bar\n    bing: bang\n    factory: core/v1/user\n"
              )
            )
          end
        end
        context 'when a factory is applied with an appropriate verb' do
          context 'when verb is POST' do
            let(:request_method) { 'POST' }
            it 'is successful' do
              expect(subject.success?).to be(true)
              expect(policy_loader).to have_received(:call).with(
                default_policy_args.merge(request_type: 'POST')
              )
            end
          end
          context 'when verb is PATCH' do
            let(:request_method) { 'PATCH' }
            it 'is successful' do
              expect(subject.success?).to be(true)
              expect(policy_loader).to have_received(:call).with(
                default_policy_args.merge(request_type: 'PATCH')
              )
            end
          end
        end
        context 'when a factory is applied with an inappropriate verb' do
          context 'when verb is DELETE' do
            let(:request_method) { 'DELETE' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'DELETE', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'DELETE')
              )
            end
          end
          context 'when verb is GET' do
            let(:request_method) { 'GET' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'GET', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'GET')
              )
            end
          end
          context 'when verb is PUT' do
            let(:request_method) { 'PUT' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'PUT', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'PUT')
              )
            end
          end
          context 'when verb is CONNECT' do
            let(:request_method) { 'CONNECT' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'CONNECT', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'CONNECT')
              )
            end
          end
          context 'when verb is OPTONS' do
            let(:request_method) { 'OPTONS' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'OPTONS', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'OPTONS')
              )
            end
          end
          context 'when verb is TRACE' do
            let(:request_method) { 'TRACE' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'TRACE', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'TRACE')
              )
            end
          end
          context 'when verb is HEAD' do
            let(:request_method) { 'HEAD' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'HEAD', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'HEAD')
              )
            end
          end
        end
      end
    end
    context 'when using a complex factory' do
      # rubocop:disable Layout/HeredocIndentation
      let(:database_factory_policy_template) do
        <<~POLICY
        - !policy
          id: {{ id }}
          annotations:
          {{#annotations}}
            {{ key }}: {{ value }}
          {{/annotations}}
          body:
          - &variables
            - !variable url
            - !variable port
            - !variable username
            - !variable password
            - !variable ssl-certificate
            - !variable ssl-key
            - !variable ssl-ca-certificate

          - !group consumers
          - !group administrators

          - !permit
            resource: *variables
            privileges: [ read, execute ]
            role: !group consumers

          - !permit
            resource: *variables
            privileges: [ update ]
            role: !group administrators

          - !grant
            member: !group administrators
            role: !group consumers
        POLICY
      end
      # rubocop:enable Layout/HeredocIndentation
      let(:database_factory) do
        # rubocop:disable Layout/LineLength
        Testing::Factories::FactoryBuilder.build(
          version: 'v1',
          schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"Database Connection Template","description":"All information for connecting to a database","type":"object","properties":{"id":{"description":"Resource Identifier","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this resource into","type":"string"},"variables":{"type":"object","properties":{"url":{"description":"Database URL","type":"string"},"port":{"description":"Database Port","type":"string"},"username":{"description":"Database Username","type":"string"},"password":{"description":"Database Password","type":"string"},"ssl-certificate":{"description":"Client SSL Certificate","type":"string"},"ssl-key":{"description":"Client SSL Key","type":"string"},"ssl-ca-certificate":{"description":"CA Root Certificate","type":"string"}},"required":["url","port","username","password"]}},"required":["branch","id","variables"]}',
          policy: database_factory_policy_template,
          policy_branch: '{{ branch }}'
        )
        # rubocop:enable Layout/LineLength
      end

      let(:factory_template) do
        DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
          encoded_factory: database_factory,
          classification: 'connections',
          version: 'v1',
          id: 'database'
        ).result
      end
      let(:request) { { id: 'bar', branch: 'foo', variables: variables }.to_json }
      # rubocop:disable Layout/LineLength
      let(:rendered_policy_body) { "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group consumers\n  - !group administrators\n\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n\n  - !grant\n    member: !group administrators\n    role: !group consumers\n" }
      # rubocop:enable Layout/LineLength
      context 'when request body is missing values' do
        # file deepcode ignore HardcodedPassword
        # file deepcode ignore HardcodedCredential: This is a test code, not an actual credential
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user' } }
        it 'returns a failure response' do
          expect(subject.success?).to be(false)
          expect(subject.message).to eq([{ message: "A value is required for '/variables/password'", key: '/variables/password' }])
          expect(subject.status).to eq(:bad_request)
        end
      end
      context 'when variable value is not a string' do
        context 'when value is an integer' do
          let(:variables) { { port: 1234, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when value is a boolean' do
          let(:variables) { { port: true, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when value is null' do
          let(:variables) { { port: nil, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
      end
      context 'when request body includes required values' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        it 'applies policy and variables' do
          expect(subject.success?).to be(true)
          expect(policy_loader).to have_received(:call).with(
            default_policy_args.merge(
              target_policy_id: 'rspec:policy:foo',
              policy: rendered_policy_body
            )
          )
          expect(secrets_repository).to have_received(:update).with(
            account: 'rspec',
            context: context,
            variables: {
              'foo/bar/port' => '1234',
              'foo/bar/url' => 'http://localhost',
              'foo/bar/username' => 'super-user',
              'foo/bar/password' => 'foo-bar'
            }
          )
        end
        context 'when factory is applied to the root policy namespace' do
          let(:request) { { id: 'bar', branch: 'root', variables: variables }.to_json }
          it 'does not append "root" to the variables' do
            expect(subject.success?).to be(true)
            expect(policy_loader).to have_received(:call).with(
              default_policy_args.merge(
                target_policy_id: 'rspec:policy:root',
                policy: rendered_policy_body
              )
            )
            expect(secrets_repository).to have_received(:update).with(
              account: 'rspec',
              context: context,
              variables: {
                'bar/port' => '1234',
                'bar/url' => 'http://localhost',
                'bar/username' => 'super-user',
                'bar/password' => 'foo-bar'
              }
            )
          end
        end
      end
      context 'when request body includes required and optional values' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar', 'ssl-certificate': 'cert-body', 'ssl-key': 'cert-key-body' } }
        it 'applies policy and relevant variables' do
          expect(subject.success?).to be(true)
          expect(policy_loader).to have_received(:call).with(
            default_policy_args.merge(
              target_policy_id: 'rspec:policy:foo',
              policy: rendered_policy_body
            )
          )
          expect(secrets_repository).to have_received(:update).with(
            account: 'rspec',
            context: context,
            variables: {
              'foo/bar/port' => '1234',
              'foo/bar/url' => 'http://localhost',
              'foo/bar/username' => 'super-user',
              'foo/bar/password' => 'foo-bar',
              'foo/bar/ssl-certificate' => 'cert-body',
              'foo/bar/ssl-key' => 'cert-key-body'
            }
          )
        end
      end
      context 'when request body includes extra variable values' do
        let(:variables) { { foo: 'bar', port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        it 'only saves variables defined in the factory' do
          expect(subject.success?).to be(true)
          expect(policy_loader).to have_received(:call).with(
            default_policy_args.merge(
              target_policy_id: 'rspec:policy:foo',
              policy: rendered_policy_body
            )
          )
          expect(secrets_repository).to have_received(:update).with(
            account: 'rspec',
            context: context,
            variables: {
              'foo/bar/port' => '1234',
              'foo/bar/url' => 'http://localhost',
              'foo/bar/username' => 'super-user',
              'foo/bar/password' => 'foo-bar'
            }
          )
          expect(subject.success?).to be(true)
        end
      end
      context 'when role is not permitted to set variables' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        context 'when role is not authorized' do
          let(:secrets_response) { ::FailureResponse.new('Role is unauthorized') }
          it 'applies policy and variables' do
            expect(subject.success?).to be(false)
            expect(policy_loader).to have_received(:call).with(
              default_policy_args.merge(
                target_policy_id: 'rspec:policy:foo',
                policy: rendered_policy_body
              )
            )
            expect(secrets_repository).to have_received(:update).with(
              account: 'rspec',
              context: context,
              variables: {
                'foo/bar/port' => '1234',
                'foo/bar/url' => 'http://localhost',
                'foo/bar/username' => 'super-user',
                'foo/bar/password' => 'foo-bar'
              }
            )
          end
        end
      end
      context 'when the factory includes default or required to include settings' do
        let(:database_factory) do
          # rubocop:disable Layout/LineLength
          Testing::Factories::FactoryBuilder.build(
            version: 'v1',
            schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"Database Connection Template","description":"All information for connecting to a database","type":"object","properties":{"id":{"description":"Resource Identifier","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this resource into","type":"string"},"variables":{"type":"object","properties":{"type":{"description":"Database Type","type":"string","default":"sqlserver","enum":["sqlserver","postgresql","mysql","oracle","db2","sqlite"]},"url":{"description":"Database URL","type":"string"},"port":{"description":"Database Port","type":"string"},"username":{"description":"Database Username","type":"string"},"password":{"description":"Database Password","type":"string"},"ssl-certificate":{"description":"Client SSL Certificate","type":"string"},"ssl-key":{"description":"Client SSL Key","type":"string"},"ssl-ca-certificate":{"description":"CA Root Certificate","type":"string"}},"required":["type","url","port","username","password"]}},"required":["branch","id","variables"]}',
            policy: database_factory_policy_template,
            policy_branch: '{{ branch }}'
          )
          # rubocop:enable Layout/LineLength
        end

        context 'when the request body variable includes an acceptable value' do
          context 'when the factory includes variables with default values' do
            context 'when the request body includes a value for the default' do
              let(:variables) { { type: 'mysql', port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
              it 'submits the policy with the provided values' do
                expect(subject.success?).to be(true)
                expect(policy_loader).to have_received(:call).with(
                  default_policy_args.merge(
                    target_policy_id: 'rspec:policy:foo',
                    policy: rendered_policy_body
                  )
                )
                expect(secrets_repository).to have_received(:update).with(
                  account: 'rspec',
                  context: context,
                  variables: {
                    'foo/bar/port' => '1234',
                    'foo/bar/url' => 'http://localhost',
                    'foo/bar/username' => 'super-user',
                    'foo/bar/password' => 'foo-bar',
                    'foo/bar/type' => 'mysql'
                  }
                )
              end
            end
            context 'when the request body does not include a value for an input with a default' do
              let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
              it 'submits the policy with the provided values' do
                expect(subject.success?).to be(true)
                expect(policy_loader).to have_received(:call).with(
                  default_policy_args.merge(
                    target_policy_id: 'rspec:policy:foo',
                    policy: rendered_policy_body
                  )
                )
                expect(secrets_repository).to have_received(:update).with(
                  account: 'rspec',
                  context: context,
                  variables: {
                    'foo/bar/port' => '1234',
                    'foo/bar/url' => 'http://localhost',
                    'foo/bar/username' => 'super-user',
                    'foo/bar/password' => 'foo-bar',
                    'foo/bar/type' => 'sqlserver'
                  }
                )
              end
            end
          end
        end
        context 'when the request body does not include a value from the enumeration' do
          let(:variables) { { type: 'foo-bar', port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns an error response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Value must be one of: 'sqlserver', 'postgresql', 'mysql', 'oracle', 'db2', 'sqlite'", key: 'variables/type' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
      end
    end
  end
end
