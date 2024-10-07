# frozen_string_literal: true

require 'spec_helper'
require 'policy_factory_helper'
require 'audit_spec_helper'

DatabaseCleaner.strategy = :truncation

def expected_factory_load_events(factory, user: 'admin')
  expect_audit(message: "rspec:user:#{user} fetched rspec:variable:conjur/factories/#{factory}", result: 'success', operation: 'fetch')
end

def expected_variable_load_events(variables = [], path: '', user: 'admin')
  variables.each do |variable|
    expect_audit(message: "rspec:user:#{user} fetched rspec:variable:#{path}/#{variable}", result: 'success', operation: 'fetch')
  end
end

def expected_simple_factory_create_events(name, type:, user: 'admin', annotations: [])
  expect_audit(message: "rspec:user:#{user} added role rspec:#{type}:#{name}", result: 'success', operation: 'add')
  expect_audit(message: "rspec:user:#{user} added resource rspec:#{type}:#{name}", result: 'success', operation: 'add')
  expect_audit(message: "rspec:user:#{user} added ownership of rspec:user:#{user} in rspec:#{type}:#{name}", result: 'success', operation: 'add')

  annotations.prepend('factory').each do |annotation|
    expect_audit(message: "rspec:user:#{user} added annotation #{annotation} on rspec:#{type}:#{name}", result: 'success', operation: 'add')
  end
end

def expected_complex_factory_create_events(name, roles:, variables:, permissions:, annotations: [], user: 'admin')
  ["policy:#{name}"].tap { |i| roles.each {|role| i << "group:#{name}/#{role}" } }.each do |resource|
    expect_audit(message: "rspec:user:#{user} added role rspec:#{resource}", result: 'success', operation: 'add')
    expect_audit(message: "rspec:user:#{user} added resource rspec:#{resource}", result: 'success', operation: 'add')
  end

  expect_audit(message: "rspec:user:#{user} added ownership of rspec:user:#{user} in rspec:policy:#{name}", result: 'success', operation: 'add')

  roles.each do |role|
    expect_audit(message: "rspec:user:#{user} added ownership of rspec:policy:#{name} in rspec:group:#{name}/#{role}", result: 'success', operation: 'add')
  end

  variables.each do |variable|
    expect_audit(message: "rspec:user:#{user} added resource rspec:variable:#{name}/#{variable}", result: 'success', operation: 'add')
  end

  permissions[:memberships].each do |parent, children|
    children.each { |child| expect_audit(message: "rspec:user:#{user} added membership of rspec:group:#{name}/#{parent} in rspec:group:#{name}/#{child}", result: 'success', operation: 'add') }
  end
  permissions[:permissions].each do |role, privileges|
    privileges.each do |privilege|
      variables.each do |variable|
        expect_audit(message: "rspec:user:#{user} added permission of rspec:group:#{name}/#{role} to #{privilege} on rspec:variable:#{name}/#{variable}", result: 'success', operation: 'add')
      end
    end
  end
  annotations.append('factory').each do |annotation|
    expect_audit(message: "rspec:user:#{user} added annotation #{annotation} on rspec:policy:#{name}", result: 'success', operation: 'add')
  end
end

def expected_set_variables_events(name, variables:, user: 'admin')
  variables.each do |variable|
    expect_audit(message: "rspec:user:#{user} updated rspec:variable:#{name}/#{variable}", result: 'success', operation: 'update')
  end
end

describe PolicyFactoryResourcesController, type: :request do
  let(:log_output) { StringIO.new }
  let(:mocked_audit_logger) do
    Audit::Log::SyslogAdapter.new(
      Logger.new(log_output).tap do |logger|
        logger.formatter = Logger::Formatter::RFC5424Formatter
      end
    )
  end

  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')

    # Policy Factories

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

    # Variable Factory

    # rubocop:disable Layout/HeredocIndentation
    database_factory_policy_template = <<~POLICY
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
    database_factory = Testing::Factories::FactoryBuilder.build(
      version: 'v1',
      schema: '{"$schema":"http://json-schema.org/draft-06/schema#","title":"Database Connection Template","description":"All information for connecting to a database","type":"object","properties":{"id":{"description":"Resource Identifier","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this resource into","type":"string"},"variables":{"type":"object","properties":{"url":{"description":"Database URL","type":"string"},"port":{"description":"Database Port","type":"string"},"username":{"description":"Database Username","type":"string"},"password":{"description":"Database Password","type":"string"},"ssl-certificate":{"description":"Client SSL Certificate","type":"string"},"ssl-key":{"description":"Client SSL Key","type":"string"},"ssl-ca-certificate":{"description":"CA Root Certificate","type":"string"}},"required":["url","port","username","password"]}},"required":["branch","id","variables"]}',
      policy: database_factory_policy_template,
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
    TEMPLATE

    post('/policies/rspec/policy/root', params: base_policy, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fcore%2Fv1%2Fuser', params: user_factory, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fcore%2Fv1%2Fpolicy', params: policy_factory, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fconnections%2Fv1%2Fdatabase', params: database_factory, env: request_env)
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
    context 'when factory is a policy factory' do
      after(:each) do
        Role['rspec:user:rspec-user-1'].delete
      end
      it 'creates resources using policy factory' do
        user_params = {
          branch: 'root',
          id: 'rspec-user-1'
        }
        allow(Audit).to receive(:logger).and_return(mocked_audit_logger)
        post('/factory-resources/rspec/core/user', params: user_params.to_json, env: request_env)

        response_json = JSON.parse(response.body)
        expect(response_json['created_roles'].key?('rspec:user:rspec-user-1')).to be(true)

        # Verify Audit messages
        expected_simple_factory_create_events('rspec-user-1', type: 'user')
        expected_factory_load_events('core/v1/user')

        # I'm Not sure why this audit is here, but it's present as a result of the standard
        # policy load process.
        expect_audit(
          message: 'rspec:user:admin changed role rspec:user:rspec-user-1',
          result: 'success',
          operation: 'change'
        )
        expect(log_output.string.split("\n").count).to eq(6)

        get('/roles/rspec/user/rspec-user-1', env: request_env)
        response_json = JSON.parse(response.body)
        expect(response_json['id']).to eq('rspec:user:rspec-user-1')
      end
    end
    context 'when a factory is a variable factory' do
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
            username: 'foo-bar',
            # file deepcode ignore HardcodedPassword: This is a test code, not an actual credential
            password: 'bar-baz'
          }
        }
        allow(Audit).to receive(:logger).and_return(mocked_audit_logger)
        post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)

        # Verify Audit messages
        expected_factory_load_events('connections/v1/database')
        expected_complex_factory_create_events(
          'test-database',
          roles: %i[consumers administrators],
          variables: %i[url port username password ssl-certificate ssl-key ssl-ca-certificate],
          permissions: { memberships: { administrators: %w[consumers] }, permissions: { consumers: %w[read execute], administrators: %w[update] } },
          annotations: ['baz']
        )
        expected_set_variables_events('test-database', variables: %w[url port username password])
        expect(log_output.string.split("\n").count).to eq(46)

        # Verify resource values
        expect(::Resource['rspec:variable:test-database/url']&.secret&.value).to eq('https://foo.bar.baz.com')
        expect(::Resource['rspec:variable:test-database/port']&.secret&.value).to eq('5432')
        expect(::Resource['rspec:variable:test-database/username']&.secret&.value).to eq('foo-bar')
        expect(::Resource['rspec:variable:test-database/password']&.secret&.value).to eq('bar-baz')
      end
    end
  end
end
