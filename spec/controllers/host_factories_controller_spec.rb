# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation

describe HostFactoriesController, type: :request do
  before(:all) do
    # Start fresh
    DatabaseCleaner.clean_with(:truncation)

    # Init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.create(role_id: 'rspec:user:admin')
  end

  # Allows API calls to be made as the admin user
  let(:admin_request_env) do
    token = Base64.strict_encode64(Slosilo["authn:rspec"].signed_token("admin").to_json)
    { 'HTTP_AUTHORIZATION' => "Token token=\"#{token}\"" }
  end

  def create_host
    post(
      "/host_factories/hosts",
      env: {
        'HTTP_AUTHORIZATION' => "Token token=\"#{host_factory_token}\"",
        'RAW_POST_DATA' => create_host_payload,
        'ACCEPT' => "application/x.secretsmgr.v2beta+json",
        'CONTENT_TYPE' => "application/x-www-form-urlencoded"
      }
    )
  end

  let(:host_factory_token) do
    HostFactoryToken.create(host_factory_token_options).token
  end

  let(:host_factory_token_options) do
    {
      resource: host_factory_resource,
      expiration: expiration
    }.tap do |options|
      options[:cidr] = cidr if cidr
    end
  end

  let(:host_factory_resource) { Resource[host_factory_resource_id] }
  let(:host_factory_resource_id) { 'rspec:host_factory:test-factory' }
  let(:expiration) { tomorrow }
  let(:cidr) { nil }

  def apply_root_policy(account, policy_content:, expect_success: false)
    post("/policies/#{account}/policy/root", env: admin_request_env.merge({ 'RAW_POST_DATA' => policy_content }))
    return unless expect_success

    expect(response.code).to eq("201")
  end

  let(:test_policy) do
    <<~POLICY
      - !layer my-test
      - !host-factory
        id: test-factory
        annotations:
          description: Factory for testing
        layers: [ !layer my-test ]

      - !user tester

      - !permit
        role: !user tester
        privilege: [ read ]
        resource: !host-factory test-factory
    POLICY
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:tomorrow) { (Time.now + (24 * 60 * 60)).utc }
  let(:yesterday) { (Time.now - (24 * 60 * 60)).utc }

  let(:create_host_payload) { "id=#{host_id}" }
  let(:host_id) { 'new-host' }

  describe '#create_host' do
    before(:each) do
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end

    context 'creating host when token in header is valid' do
      it 'returns a 201' do
        create_host
        expect(response.code).to eq('201')
      end

      context 'request body parameters are not formatted correctly' do
        context 'request body is empty' do
          let(:create_host_payload) { "" }

          it 'returns a 422' do
            create_host
            expect(response.code).to eq('422')
          end
        end

        context 'id parameter is not formatted correctly' do
          let(:create_host_payload) { "non-id-parameter=new-host" }

          it 'returns a 422' do
            create_host
            expect(response.code).to eq('422')
          end
        end

        context 'id parameter starts with /conjur/' do
          let(:host_id) { '/conjur/' }

          it 'raises an argument error' do
            create_host
            expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid id: /conjur/" } })
          end
        end
      end
    end

    context 'creating host when token in header is invalid' do
      context 'when the token is formatted incorrectly' do
        let(:host_factory_token) { "non-token" }

        it 'returns a 401' do
          create_host
          expect(response.code).to eq('401')
        end
      end

      context 'when the token is expired' do
        let(:expiration) { yesterday }

        it 'returns a 401' do
          create_host
          expect(response.code).to eq('401')
        end
      end

      context 'when the token is using incorrect resource' do
        # The 'kind' in the token must be 'host_factory', not any other kind
        let(:host_factory_resource_id) { 'rspec:user:tester'}

        it 'raises an argument error' do
          create_host

          expect(response.code).to eq('422')
          expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid resource kind: user" } })
        end
      end
    end
  end
end
