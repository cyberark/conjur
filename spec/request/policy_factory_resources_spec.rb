# frozen_string_literal: true

require 'spec_helper'
require 'policy_factory_helper'

DatabaseCleaner.strategy = :truncation

describe PolicyFactoryResourcesController, type: :request do
  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')

    # Simple Factories

    # rubocop:disable Layout/HeredocIndentation
    user_factory_policy_template = <<~POLICY
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
    user_factory = Testing::Factories::FactoryBuilder.build(
      version: 'v1',
      schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"User Template","description":"Creates a Conjur User","type":"object","properties":{"id":{"description":"User ID","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this user into","type":"string"},"owner_role":{"description":"The Conjur Role that will own this user","type":"string"},"owner_type":{"description":"The resource type of the owner of this user","type":"string"},"ip_range":{"description":"Limits the network range the user is allowed to authenticate from","type":"string"}},"required":["branch","id"]}',
      policy: user_factory_policy_template,
      policy_branch: '{{ branch }}'
    )
    # rubocop:enable Layout/LineLength

    # rubocop:disable Layout/HeredocIndentation
    policy_factory_policy_template = <<~POLICY
    - !policy
      id: {{ id }}
    {{#owner_role}}
      {{#owner_type}}
      owner: !{{ owner_type }} {{ owner_role }}
      {{/owner_type}}
    {{/owner_role}}
      annotations:
      {{#annotations}}
        {{ key }}: {{ value }}
      {{/annotations}}
    POLICY
    # rubocop:enable Layout/HeredocIndentation

    # rubocop:disable Layout/LineLength
    policy_factory = Testing::Factories::FactoryBuilder.build(
      version: 'v1',
      schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"Policy Template","description":"Creates a Conjur Policy","type":"object","properties":{"id":{"description":"Policy ID","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this policy into","type":"string"},"owner_role":{"description":"The Conjur Role that will own this policy","type":"string"},"owner_type":{"description":"The resource type of the owner of this policy","type":"string"}},"required":["branch","id"]}',
      policy: policy_factory_policy_template,
      policy_branch: '{{ branch }}'
    )
    # rubocop:enable Layout/LineLength

    # Complex Factory

    # rubocop:disable Layout/HeredocIndentation
    database_factory_without_breaker_policy_template = <<~POLICY
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
    # rubocop:enable Layout/HeredocIndentation

    # rubocop:disable Layout/LineLength
    database_factory_without_breaker = Testing::Factories::FactoryBuilder.build(
      version: 'v1',
      schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"Database Connection Template","description":"All information for connecting to a database","type":"object","properties":{"id":{"description":"Resource Identifier","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this resource into","type":"string"},"variables":{"type":"object","properties":{"url":{"description":"Database URL","type":"string"},"port":{"description":"Database Port","type":"string"},"username":{"description":"Database Username","type":"string"},"password":{"description":"Database Password","type":"string"},"ssl-certificate":{"description":"Client SSL Certificate","type":"string"},"ssl-key":{"description":"Client SSL Key","type":"string"},"ssl-ca-certificate":{"description":"CA Root Certificate","type":"string"}},"required":["url","port","username","password"]}},"required":["branch","id","variables"]}',
      policy: database_factory_without_breaker_policy_template,
      policy_branch: '{{ branch }}'
    )
    # rubocop:enable Layout/LineLength

    # rubocop:disable Layout/HeredocIndentation
    database_factory_with_breaker_policy_template = <<~POLICY
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

        - !group
          id: consumers
          annotations:
            description: "Roles that can see and retrieve credentials."

        - !group
          id: administrators
          annotations:
            description: "Roles that can update credentials."

        - !group
          id: circuit-breaker
          annotations:
            description: Provides a mechanism for breaking access to this authenticator.
            editable: true

        # Allows 'consumers' group to be cut in case of compromise
        - !grant
          member: !group consumers
          role: !group circuit-breaker

        # Administrators also has the consumers role
        - !grant
          member: !group administrators
          role: !group consumers

        # Consumers (via the circuit-breaker group) can read and execute
        - !permit
          resource: *variables
          privileges: [ read, execute ]
          role: !group circuit-breaker

        # Administrators can update (they have read and execute via the consumers group)
        - !permit
          resource: *variables
          privileges: [ update ]
          role: !group administrators
    POLICY
    # rubocop:enable Layout/HeredocIndentation

    # rubocop:disable Layout/LineLength
    database_factory = Testing::Factories::FactoryBuilder.build(
      version: 'v1',
      schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"Database Connection Template","description":"All information for connecting to a database","type":"object","properties":{"id":{"description":"Resource Identifier","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this resource into","type":"string"},"variables":{"type":"object","properties":{"url":{"description":"Database URL","type":"string"},"port":{"description":"Database Port","type":"string"},"username":{"description":"Database Username","type":"string"},"password":{"description":"Database Password","type":"string"},"ssl-certificate":{"description":"Client SSL Certificate","type":"string"},"ssl-key":{"description":"Client SSL Key","type":"string"},"ssl-ca-certificate":{"description":"CA Root Certificate","type":"string"}},"required":["url","port","username","password"]}},"required":["branch","id","variables"]}',
      policy: database_factory_with_breaker_policy_template,
      policy_branch: '{{ branch }}'
    )
    # rubocop:enable Layout/LineLength

    base_policy = <<~TEMPLATE
      - !policy
        id: conjur
        body:
        - !policy
          id: factories
          body:
          - !policy
            id: core
            annotations:
              description: "Create Conjur primatives and manage permissions"
            body:
            - !variable v1/user
            - !variable v1/policy

          - !policy
            id: connections
            annotations:
              description: "Create connections to external services"
            body:
            - !variable v1/database
            - !variable v2/database
    TEMPLATE

    post('/policies/rspec/policy/root', params: base_policy, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fcore%2Fv1%2Fuser', params: user_factory, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fcore%2Fv1%2Fpolicy', params: policy_factory, env: request_env)

    # V1 includes the factory without circuit breakers
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fconnections%2Fv1%2Fdatabase', params: database_factory_without_breaker, env: request_env)
    # V2 includes the factory with circuit breakers
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fconnections%2Fv2%2Fdatabase', params: database_factory, env: request_env)
  end

  after(:all) do
    base_policy = <<~TEMPLATE
      - !delete
        record: !variable conjur/factories/core/v1/user
      - !delete
        record: !variable conjur/factories/core/v1/policy
      - !delete
        record: !policy conjur/factories/core
      - !delete
        record: !policy conjur/factories/connections
      - !delete
        record: !policy conjur/factories
      - !delete
        record: !policy conjur
    TEMPLATE

    patch('/policies/rspec/policy/root', params: base_policy, env: request_env)
  end

  def request_env(role: 'admin')
    {
      'HTTP_AUTHORIZATION' => access_token_for(role)
    }
  end

  describe 'POST #create' do
    context 'when policy factory is simple' do
      after(:each) do
        Role['rspec:user:rspec-user-1'].delete
      end
      it 'creates resources using policy factory' do
        user_params = {
          branch: 'root',
          id: 'rspec-user-1'
        }
        post('/factory-resources/rspec/core/user', params: user_params.to_json, env: request_env)
        response_json = JSON.parse(response.body)
        expect(response_json['created_roles'].key?('rspec:user:rspec-user-1')).to be(true)

        get('/roles/rspec/user/rspec-user-1', env: request_env)
        response_json = JSON.parse(response.body)
        expect(response_json['id']).to eq('rspec:user:rspec-user-1')
      end
    end
    context 'when policy factory is complex' do
      after(:each) do
        Resource['rspec:variable:test-database/url'].delete
        Resource['rspec:variable:test-database/port'].delete
        Resource['rspec:variable:test-database/username'].delete
        Resource['rspec:variable:test-database/password'].delete
        Role['rspec:policy:test-database'].delete
      end
      it 'creates resources using policy factory' do
        database_params = {
          id: 'test-database',
          branch: 'root',
          annotations: { foo: 'bar', baz: 'bang' },
          variables: {
            url: 'https://foo.bar.baz.com',
            port: '5432',
            # file deepcode ignore HardcodedPassword
            # file deepcode ignore HardcodedCredential: This is a test code, not an actual credential
            username: 'foo-bar',
            password: 'bar-baz'
          }
        }
        post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)

        expect(response.status).to eq(201)
        expect(::Resource['rspec:variable:test-database/url']&.secret&.value).to eq('https://foo.bar.baz.com')
        expect(::Resource['rspec:variable:test-database/port']&.secret&.value).to eq('5432')
        expect(::Resource['rspec:variable:test-database/username']&.secret&.value).to eq('foo-bar')
        expect(::Resource['rspec:variable:test-database/password']&.secret&.value).to eq('bar-baz')
      end
    end
  end
  describe 'GET #show' do
    context 'when the requested resource was created from a "simple" factory' do
      context 'if the requested resource is a policy without variables' do
        before(:each) do
          policy_params = {
            branch: 'root',
            id: 'test-policy-1'
          }
          post('/factory-resources/rspec/core/policy', params: policy_params.to_json, env: request_env)
        end
        after(:each) do
          Role['rspec:policy:test-policy-1'].delete
        end
        it 'is unsuccessful' do
          get('/factory-resources/rspec/test-policy-1', env: request_env)

          response_json = JSON.parse(response.body)

          expect(response.status).to eq(404)
          expect(response_json).to eq({
            "code" => 404,
            "error" => { "message" => "This factory created resource: 'rspec:policy:test-policy-1' does not include any variables." }
          })
        end
      end
      context 'when the requested resource is not a policy' do
        before(:each) do
          user_params = {
            branch: 'root',
            id: 'rspec-user-1'
          }
          post('/factory-resources/rspec/core/user', params: user_params.to_json, env: request_env)
        end
        after(:each) do
          Role['rspec:user:rspec-user-1'].delete
        end

        it 'responds with an error' do
          get('/factory-resources/rspec/rspec-user-1', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(404)
          expect(response_json).to eq({
            "code" => 404,
            "error" => {
              "message" => "Policy 'rspec-user-1' was not found in account 'rspec'. Only policies with variables created from Factories can be retrieved using the Factory endpoint."
            }
          })
        end
      end
    end
    context 'when the requested resource was created from a "complex" factory' do
      context 'when the requested resource is present' do
        let(:database_factory_result) do
          {
            "annotations" => { "foo" => "bar", "baz" => "bang" },
            "id" => "test-database",
            "details" => { "classification" => "connections", "identifier" => "database", "version" => "v1" },
            "variables" => {
              "url" => {
                "value" => "https://foo.bar.baz.com",
                "description" => "Database URL"
              },
              "port" => {
                "value" => "5432",
                "description" => "Database Port"
              },
              "username" => {
                "value" => "foo-bar",
                "description" => "Database Username"
              },
              "password" => {
                "value" => "bar-baz",
                "description" => "Database Password"
              },
              "ssl-ca-certificate" => {
                "description" => "CA Root Certificate",
                "value" => nil
              }, "ssl-certificate" => {
                "description" => "Client SSL Certificate",
                "value" => nil
              }, "ssl-key" => {
                "description" => "Client SSL Key",
                "value" => nil
              }
            }
          }
        end
        context 'when the factory is created in the root namespace' do
          before(:each) do
            database_params = {
              id: 'test-database',
              branch: 'root',
              annotations: { foo: 'bar', baz: 'bang' },
              variables: {
                url: 'https://foo.bar.baz.com',
                port: '5432',
                username: 'foo-bar',
                password: 'bar-baz'
              }
            }
            post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
          end
          after(:each) do
            Resource['rspec:variable:test-database/url'].delete
            Resource['rspec:variable:test-database/port'].delete
            Resource['rspec:variable:test-database/username'].delete
            Resource['rspec:variable:test-database/password'].delete
            Role['rspec:policy:test-database'].delete
          end

          it 'returns the factory resource' do
            get('/factory-resources/rspec/test-database', env: request_env)
            response_json = JSON.parse(response.body)

            expect(response.status).to eq(200)
            expect(response_json).to eq(database_factory_result)
          end
        end
        context 'when the factory is created in an interior namespace' do
          before(:each) do
            post('/factory-resources/rspec/core/policy', params: { id: 'foo', branch: 'root' }.to_json, env: request_env)
            post('/factory-resources/rspec/core/policy', params: { id: 'bar', branch: 'foo' }.to_json, env: request_env)
            post('/factory-resources/rspec/core/policy', params: { id: 'baz', branch: 'foo/bar' }.to_json, env: request_env)

            database_params = {
              id: 'test-database',
              branch: 'foo/bar/baz',
              annotations: { foo: 'bar', baz: 'bang' },
              variables: {
                url: 'https://foo.bar.baz.com',
                port: '5432',
                username: 'foo-bar',
                password: 'bar-baz'
              }
            }
            post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
          end
          after(:each) do
            Resource['rspec:variable:foo/bar/baz/test-database/url'].delete
            Resource['rspec:variable:foo/bar/baz/test-database/port'].delete
            Resource['rspec:variable:foo/bar/baz/test-database/username'].delete
            Resource['rspec:variable:foo/bar/baz/test-database/password'].delete
            Role['rspec:policy:foo/bar/baz/test-database'].delete
          end

          it 'returns the factory resource' do
            get('/factory-resources/rspec/foo%2Fbar%2Fbaz%2Ftest-database', env: request_env)
            response_json = JSON.parse(response.body)

            expect(response.status).to eq(200)
            expect(response_json).to eq(
              database_factory_result.merge(
                "id" => "foo/bar/baz/test-database"
              )
            )
            expect(::Resource['rspec:variable:foo/bar/baz/test-database/url']&.secret&.value).to eq('https://foo.bar.baz.com')
            expect(::Resource['rspec:variable:foo/bar/baz/test-database/port']&.secret&.value).to eq('5432')
            expect(::Resource['rspec:variable:foo/bar/baz/test-database/username']&.secret&.value).to eq('foo-bar')
            expect(::Resource['rspec:variable:foo/bar/baz/test-database/password']&.secret&.value).to eq('bar-baz')
          end
        end
      end
      context 'when the requested resource is not present' do
        it 'responds with an error' do
          get('/factory-resources/rspec/test-database', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(404)
          expect(response_json).to eq({
            "code" => 404,
            "error" => {
              "message" => "Policy 'test-database' was not found in account 'rspec'. Only policies with variables created from Factories can be retrieved using the Factory endpoint."
            }
          })
        end
      end
    end
  end
  describe 'GET #index' do
    context 'when no complex factory resources are available' do
      context 'when no resources have been created with simple factories' do
        it 'responds with an empty set' do
          get('/factory-resources/rspec', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json).to eq([])
        end
      end
      context 'when simple factory resources have been created' do
        before(:each) do
          user_params = {
            branch: 'root',
            id: 'rspec-user-1'
          }
          post('/factory-resources/rspec/core/user', params: user_params.to_json, env: request_env)
        end
        after(:each) do
          Role['rspec:user:rspec-user-1'].delete
        end
        it 'responds with an empty set' do
          get('/factory-resources/rspec', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json).to eq([])
        end
      end
      context 'when role does not have access to created resources' do
        before(:each) do
          database_params = {
            id: 'test-database',
            branch: 'root',
            annotations: { foo: 'bar', baz: 'bang' },
            variables: {
              url: 'https://foo.bar.baz.com',
              port: '5432',
              username: 'foo-bar',
              password: 'bar-baz'
            }
          }
          post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
          post('/factory-resources/rspec/core/user', params: { branch: 'root', id: 'rspec-user-1' }.to_json, env: request_env)
        end
        after(:each) do
          Resource['rspec:variable:test-database/url'].delete
          Resource['rspec:variable:test-database/port'].delete
          Resource['rspec:variable:test-database/username'].delete
          Resource['rspec:variable:test-database/password'].delete
          Role['rspec:policy:test-database'].delete
          Role['rspec:user:rspec-user-1'].delete
        end
        it 'responds with an empty set' do
          get('/factory-resources/rspec', env: request_env(role: 'rspec-user-1'))
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json).to eq([])
        end
      end
    end
    context 'when complex factory resources are available' do
      before(:each) do
        database_params = {
          id: 'test-database',
          branch: 'root',
          variables: {
            url: 'https://foo.bar.baz.com',
            port: '5432',
            username: 'foo-bar',
            password: 'bar-baz'
          }
        }
        post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
      end
      after(:each) do
        Resource['rspec:variable:test-database/url'].delete
        Resource['rspec:variable:test-database/port'].delete
        Resource['rspec:variable:test-database/username'].delete
        Resource['rspec:variable:test-database/password'].delete
        Role['rspec:policy:test-database'].delete
      end
      context 'when one resource has been created' do
        it 'responds with the created resource' do
          get('/factory-resources/rspec', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json).to eq([{
            'annotations' => {},
            'details' => {
              'classification' => 'connections',
              'identifier' => 'database',
              'version' => 'v1'
            },
            'id' => 'test-database',
            'variables' => {
              'password' => {
                'description' => 'Database Password',
                'value' => 'bar-baz'
              },
              'port' => {
                'description' => 'Database Port',
                'value' => '5432'
              },
              'ssl-ca-certificate' => {
                'description' => 'CA Root Certificate',
                'value' => nil
              },
              'ssl-certificate' => {
                'description' => 'Client SSL Certificate',
                'value' => nil
              },
              'ssl-key' => {
                'description' => 'Client SSL Key',
                'value' => nil
              },
              'url' => {
                'description' => 'Database URL',
                'value' => 'https://foo.bar.baz.com'
              },
              'username' => {
                'description' => 'Database Username',
                'value' => 'foo-bar'
              }
            }
          }])
        end
      end
      context 'when multiple resources have been created' do
        before(:each) do
          database_params = {
            id: 'test-database-2',
            branch: 'root',
            variables: {
              url: 'https://foo.bar.baz.com',
              port: '5432',
              username: 'foo-bar',
              password: 'bar-baz'
            }
          }
          post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
        end
        after(:each) do
          Resource['rspec:variable:test-database-2/url'].delete
          Resource['rspec:variable:test-database-2/port'].delete
          Resource['rspec:variable:test-database-2/username'].delete
          Resource['rspec:variable:test-database-2/password'].delete
          Role['rspec:policy:test-database-2'].delete
        end
        it 'responds with the created resources' do
          get('/factory-resources/rspec', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json.count).to eq(2)
          expect(response_json.first['id']).to eq('test-database')
          expect(response_json.last['id']).to eq('test-database-2')
        end
        context 'when a role does not have permission to view all resources' do
          before(:each) do
            # grant rspec-user-1 the role of consumer on test-database-2
            post('/factory-resources/rspec/core/user', params: { branch: 'root', id: 'rspec-user-1' }.to_json, env: request_env)
            grant_policy = <<~TEMPLATE
              - !grant
                member: !user rspec-user-1
                role: !group test-database-2/consumers
            TEMPLATE
            post('/policies/rspec/policy/root', params: grant_policy, env: request_env)
          end
          after(:each) do
            Role['rspec:user:rspec-user-1'].delete
          end
          it 'responds with an empty set' do
            get('/factory-resources/rspec', env: request_env(role: 'rspec-user-1'))
            response_json = JSON.parse(response.body)

            expect(response.status).to eq(200)
            expect(response_json.count).to eq(1)
            expect(response_json.first['id']).to eq('test-database-2')
          end
        end
      end
    end
  end
  describe 'POST #enable' do
    context 'when resource has been created from a factory' do
      context 'when the created resource is in the root policy' do
        after(:each) do
          Resource['rspec:variable:test-database/url']&.delete
          Resource['rspec:variable:test-database/port']&.delete
          Resource['rspec:variable:test-database/username']&.delete
          Resource['rspec:variable:test-database/password']&.delete
          Role['rspec:policy:test-database']&.delete
        end
        context 'when a factory does not have circuit breakers' do
          it 'is returns an error' do
            database_params = {
              id: 'test-database',
              branch: 'root',
              variables: {
                url: 'https://foo.bar.baz.com',
                port: '5432',
                username: 'foo-bar',
                password: 'bar-baz'
              }
            }
            post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
            post('/factory-resources/rspec/test-database/enable', env: request_env)

            expect(response.status).to eq(501)
            response_json = JSON.parse(response.body)
            expect(response_json['error']['message']).to eq("Factory generated policy 'test-database' does not include a circuit-breaker group.")
          end
        end
        context 'when factory has circuit breakers' do
          context 'when the resource is currently enabled' do
            context 'when we attempt to enable it again' do
              it 'is successful' do
                database_params = {
                  id: 'test-database',
                  branch: 'root',
                  variables: {
                    url: 'https://foo.bar.baz.com',
                    port: '5432',
                    username: 'foo-bar',
                    password: 'bar-baz'
                  }
                }
                post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
                post('/factory-resources/rspec/test-database/enable', env: request_env)

                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                ).to eq(true)
              end
            end
          end
          context 'when the resource is currently disabled' do
            context 'when we attempt to enable it' do
              it 'restores access' do
                database_params = {
                  id: 'test-database',
                  branch: 'root',
                  variables: {
                    url: 'https://foo.bar.baz.com',
                    port: '5432',
                    username: 'foo-bar',
                    password: 'bar-baz'
                  }
                }
                post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
                post('/factory-resources/rspec/test-database/disable', env: request_env)
                # verify disabled
                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                ).to eq(false)

                # then enable
                post('/factory-resources/rspec/test-database/enable', env: request_env)
                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                ).to eq(true)
              end
            end
          end
        end
      end
      context 'when the created resource is in an interior policy' do
        before(:each) do
          post(
            '/factory-resources/rspec/core/policy',
            params: { branch: 'root', id: 'test-policy-1' }.to_json,
            env: request_env
          )
          database_params = {
            id: 'test-database-2',
            branch: 'test-policy-1',
            variables: {
              url: 'https://foo.bar.baz.com',
              port: '5432',
              username: 'foo-bar',
              password: 'bar-baz'
            }
          }
          post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
        end
        after(:each) do
          Resource['rspec:variable:test-policy-1/test-database-2/url'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/port'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/username'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/password'].delete
          Role['rspec:group:test-policy-1/test-database-2/consumers'].delete
          Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].delete
          Role['rspec:group:test-policy-1/test-database-2/administrators'].delete
          Role['rspec:policy:test-policy-1/test-database-2'].delete
          Role['rspec:policy:test-policy-1'].delete
        end
        context 'when the resource is currently disabled' do
          context 'when we attempt to enable it' do
            it 'restores access' do
              # Trip the circuit breaker
              post('/factory-resources/rspec/test-policy-1%2Ftest-database-2/disable', env: request_env)
              # Verify it is disabled
              expect(response.status).to eq(200)
              expect(
                Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
              ).to eq(false)

              # Enable
              post('/factory-resources/rspec/test-policy-1%2Ftest-database-2/enable', env: request_env)
              expect(response.status).to eq(200)
              expect(
                Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-policy-1/test-database-2/consumers' }
              ).to eq(true)
            end
          end
        end
      end
    end
  end
  describe 'POST #disable' do
    context 'when a resource has been created from a factory' do
      context 'when the created resource is in the root policy' do
        after(:each) do
          Resource['rspec:variable:test-database/url']&.delete
          Resource['rspec:variable:test-database/port']&.delete
          Resource['rspec:variable:test-database/username']&.delete
          Resource['rspec:variable:test-database/password']&.delete
          Role['rspec:policy:test-database']&.delete
        end
        context 'when a factory does not have circuit breaker' do
          it 'returns an error' do
            database_params = {
              id: 'test-database',
              branch: 'root',
              variables: {
                url: 'https://foo.bar.baz.com',
                port: '5432',
                username: 'foo-bar',
                password: 'bar-baz'
              }
            }
            post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
            post('/factory-resources/rspec/test-database/disable', env: request_env)

            expect(response.status).to eq(501)
            response_json = JSON.parse(response.body)
            expect(response_json['error']['message']).to eq("Factory generated policy 'test-database' does not include a circuit-breaker group.")
          end
        end
        context 'when factory has a circuit breaker' do
          context 'when the resource is currently disabled' do
            context 'when we attempt to disable it again' do
              it 'is successful' do
                database_params = {
                  id: 'test-database',
                  branch: 'root',
                  variables: {
                    url: 'https://foo.bar.baz.com',
                    port: '5432',
                    username: 'foo-bar',
                    password: 'bar-baz'
                  }
                }
                post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
                post('/factory-resources/rspec/test-database/disable', env: request_env)

                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                ).to eq(false)
              end
            end
          end
          context 'when the resource is currently enabled' do
            context 'when we attempt to disable it' do
              before(:each) do
                database_params = {
                  id: 'test-database',
                  branch: 'root',
                  annotations: { foo: 'bar', baz: 'bang' },
                  variables: {
                    url: 'https://foo.bar.baz.com',
                    port: '5432',
                    username: 'foo-bar',
                    password: 'bar-baz'
                  }
                }
                post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
                # verify the breaker has not been tripped
                unless Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                  post('/factory-resources/rspec/test-database/enable', env: request_env)
                  expect(response.status).to eq(200)
                  expect(
                    Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                  ).to eq(true)
                end
              end
              context 'when the role has update permission on the policy' do
                it 'removes access' do
                  post('/factory-resources/rspec/test-database/disable', env: request_env)
                  # verify disabled
                  expect(response.status).to eq(200)
                  expect(
                    Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                  ).to eq(false)
                end
              end
              context 'when the role does not have update permission on the policy' do
                before(:each) do
                  Role.find_or_create(role_id: 'rspec:user:alice')
                end
                after(:each) do
                  Role['rspec:user:alice'].delete
                end
                it 'responds with an error' do
                  post('/factory-resources/rspec/test-database/disable', env: request_env(role: 'alice'))
                  # verify circuit breaker is not disabled
                  expect(response.status).to eq(403)
                  expect(
                    Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                  ).to eq(true)
                end
              end
            end
          end
        end
      end
      context 'when the created resource is in an interior policy' do
        before(:each) do
          post(
            '/factory-resources/rspec/core/policy',
            params: { branch: 'root', id: 'test-policy-1' }.to_json,
            env: request_env
          )
          database_params = {
            id: 'test-database-2',
            branch: 'test-policy-1',
            variables: {
              url: 'https://foo.bar.baz.com',
              port: '5432',
              username: 'foo-bar',
              password: 'bar-baz'
            }
          }
          post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
        end
        after(:each) do
          Resource['rspec:variable:test-policy-1/test-database-2/url'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/port'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/username'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/password'].delete
          Role['rspec:group:test-policy-1/test-database-2/consumers'].delete
          Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].delete
          Role['rspec:group:test-policy-1/test-database-2/administrators'].delete
          Role['rspec:policy:test-policy-1/test-database-2'].delete
          Role['rspec:policy:test-policy-1'].delete
        end
        context 'when the resource is currently enabled' do
          context 'when we attempt to disable it' do
            it 'removes access' do
              # verify the breaker has not been tripped
              unless Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-policy-1/test-database-2/consumers' }
                post('/factory-resources/rspec/test-policy-1%2Ftest-database-2/enable', env: request_env)
                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-policy-1/test-database-2/consumers' }
                ).to eq(true)
              end

              post('/factory-resources/rspec/test-policy-1%2Ftest-database-2/disable', env: request_env)
              # verify disabled
              expect(response.status).to eq(200)
              expect(
                Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
              ).to eq(false)
            end
          end
        end
      end
    end
  end
end
