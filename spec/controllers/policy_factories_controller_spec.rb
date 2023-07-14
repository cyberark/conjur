# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe PolicyFactoriesController, type: :request do
  before(:all) do
    init_slosilo_keys("rspec")

    admin_user = Role.find_or_create(role_id: 'rspec:user:admin')
    post(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge({ 'RAW_POST_DATA' => Factories::Templates::Base::V1::BasePolicy.policy })
    )
    {
      'core/v1/group' => Factories::Templates::Core::V1::Group.data,
      'core/v1/user' => Factories::Templates::Core::V1::User.data
    }.each do |factory, data|
      post(
        "/secrets/rspec/variable/conjur/factories/#{factory}",
        env: token_auth_header(role: admin_user).merge({ 'RAW_POST_DATA' => data })
      )
    end
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  describe '#index' do
    context 'when user has permission' do
      context 'it shows available factories' do
        it 'displays expected values' do
          get(
            '/factories/rspec',
            env: token_auth_header(role: current_user)
          )
          result = JSON.parse(response.body)
          expect(response.code).to eq('200')
          expect(result['core'].length).to eq(2)
          expect(result['core']).to include({
            'name' => 'group',
            'namespace' => 'core',
            'full-name' => 'core/group',
            'current-version' => 'v1',
            'description' => 'Creates a Conjur Group'
          })
          expect(result['core']).to include({
            'name' => 'user',
            'namespace' => 'core',
            'full-name' => 'core/user',
            'current-version' => 'v1',
            'description' => 'Creates a Conjur User'
          })
        end
      end
    end
    context 'when role does not have permission' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:foo-bar') }
      it 'returns an appropriate error response' do
        get(
          '/factories/rspec',
          env: token_auth_header(role: current_user)
        )
        result = JSON.parse(response.body)
        expect(response.code).to eq('403')
        expect(result).to eq({
          'code' => 403,
          'error' => {
            'message' => 'Role does not have permission to use Factories'
          }
        })
      end
    end
  end

  describe '#show' do
    let(:desired_result) do
      {
        'title' => 'User Template',
        'version' => 'v1',
        'description' => 'Creates a Conjur User',
        'properties' => {
          'id' => {
            'description' => 'User ID',
            'type' => 'string'
          },
          'branch' => {
            'description' => 'Policy branch to load this user into',
            'type' => 'string'
          },
          'owner_role' => {
            'description' => 'The Conjur Role that will own this user',
            'type' => 'string'
          },
          'owner_type' => {
            'description' => 'The resource type of the owner of this user',
            'type' => 'string'
          },
          'ip_range' => {
            'description' => 'Limits the network range the user is allowed to authenticate from',
            'type' => 'string'
          },
          'annotations' => {
            'description' => 'Additional annotations',
            'type' => 'object'
          }
        },
        'required' => %w[id branch]
      }
    end
    context 'when role has permission to access' do
      context 'when version is included in request' do
        it 'returns the expected response' do
          get(
            '/factories/rspec/core/v1/user',
            env: token_auth_header(role: current_user)
          )
          result = JSON.parse(response.body)
          expect(response.code).to eq('200')
          expect(result).to eq(desired_result)
        end
      end
      context 'when version is not present in request' do
        it 'returns the latest version' do
          get(
            '/factories/rspec/core/user',
            env: token_auth_header(role: current_user)
          )
          result = JSON.parse(response.body)
          expect(response.code).to eq('200')
          expect(result).to eq(desired_result)
        end
      end
    end
    context 'when factory does not exist' do
      it 'returns the expected response' do
        get(
          '/factories/rspec/core/v1/fake-factory',
          env: token_auth_header(role: current_user)
        )
        result = JSON.parse(response.body)
        expect(response.code).to eq('404')
        expect(result).to eq({
          'code' => 404,
          'error' => {
            'message' => 'Requested Policy Factory does not exist',
            'resource' => 'core/v1/fake-factory'
          }
        })
      end
    end
  end
  describe '#create' do
    context 'when a factory exists' do
      context 'when role has permission to create from the factory' do
        let(:policy_creator) { instance_double(Factories::CreateFromPolicyFactory) }
        let(:double_class) { class_double(Factories::CreateFromPolicyFactory).as_stubbed_const }

        before do
          allow(double_class).to receive(:new).and_return(policy_creator)
          allow(policy_creator).to receive(:call).and_return(::SuccessResponse.new('success!!'))
        end

        it 'creates the desire resource' do
          auth_headers = token_auth_header(role: current_user)
          request_body = {
            'id': 'test-user-1',
            'branch': 'root'
          }.to_json
          post(
            '/factories/rspec/core/user',
            env: auth_headers.merge({ 'RAW_POST_DATA' => request_body })
          )

          # We're really only checking that the Factories::CreateFromPolicyFactory.call method
          # is called with expected arguements. We're testing this class separately.
          decoded_factory = JSON.parse(Base64.decode64(Factories::Templates::Core::V1::User.data))
          expect(policy_creator).to have_received(:call).with({
            account: 'rspec',
            factory_template: DB::Repository::DataObjects::PolicyFactory.new(
              policy: Base64.decode64(decoded_factory['policy']),
              policy_branch: decoded_factory['policy_branch'],
              schema: decoded_factory['schema'],
              version: 'v1',
              name: 'user',
              classification: 'core',
              description: decoded_factory['schema']&.dig('description').to_s
            ),
            request_body: { id: 'test-user-1', branch: 'root' }.to_json,
            authorization: auth_headers['HTTP_AUTHORIZATION']
          })
          expect(response.code).to eq('200')
          # This response is mocked. We're not really returning this in real life.
          # Tests on Factories::CreateFromPolicyFactory verify that we always receive
          # a success of failure object.
          expect(response.body).to eq('success!!')
        end
      end
    end
  end
end
