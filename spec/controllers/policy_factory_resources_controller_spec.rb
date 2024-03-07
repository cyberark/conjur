# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe PolicyFactoryResourcesController, type: :request do
  def user_factory
    # rubocop:disable Layout/LineLength
    'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoZFhObGNnb2dJR2xrT2lBOEpUMGdhV1FnSlQ0S1BDVWdhV1lnWkdWbWFXNWxaRDhvYjNkdVpYSmZjbTlzWlNrZ0ppWWdaR1ZtYVc1bFpEOG9iM2R1WlhKZmRIbHdaU2tnTFNVK0NpQWdiM2R1WlhJNklDRThKVDBnYjNkdVpYSmZkSGx3WlNBbFBpQThKVDBnYjNkdVpYSmZjbTlzWlNBbFBnbzhKU0JsYm1RZ0xTVStDandsSUdsbUlHUmxabWx1WldRL0tHbHdYM0poYm1kbEtTQXRKVDRLSUNCeVpYTjBjbWxqZEdWa1gzUnZPaUE4SlQwZ2FYQmZjbUZ1WjJVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiVXNlciBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQ3JlYXRlcyBhIENvbmp1ciBVc2VyIiwidHlwZSI6Im9iamVjdCIsInByb3BlcnRpZXMiOnsiaWQiOnsiZGVzY3JpcHRpb24iOiJVc2VyIElEIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHVzZXIgaW50byIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfcm9sZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBDb25qdXIgUm9sZSB0aGF0IHdpbGwgb3duIHRoaXMgdXNlciIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfdHlwZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSByZXNvdXJjZSB0eXBlIG9mIHRoZSBvd25lciBvZiB0aGlzIHVzZXIiLCJ0eXBlIjoic3RyaW5nIn0sImlwX3JhbmdlIjp7ImRlc2NyaXB0aW9uIjoiTGltaXRzIHRoZSBuZXR3b3JrIHJhbmdlIHRoZSB1c2VyIGlzIGFsbG93ZWQgdG8gYXV0aGVudGljYXRlIGZyb20iLCJ0eXBlIjoic3RyaW5nIn19LCJyZXF1aXJlZCI6WyJicmFuY2giLCJpZCJdfX0='
    # rubocop:enable Layout/LineLength
  end

  def base_policy
    <<~TEMPLATE
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
    TEMPLATE
  end

  before(:all) do
    Slosilo['authn:rspec'] ||= Slosilo::Key.new
    admin_user = Role.find_or_create(role_id: 'rspec:user:admin')

    post(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge({ 'RAW_POST_DATA' => base_policy })
    )
    {
      'core/v1/user' => user_factory
    }.each do |factory, data|
      post(
        "/secrets/rspec/variable/conjur/factories/#{factory}",
        env: token_auth_header(role: admin_user).merge({ 'RAW_POST_DATA' => data })
      )
    end
  end
  after(:all) do
    request_env = {
      'HTTP_AUTHORIZATION' => access_token_for('admin')
    }

    base_policy = <<~TEMPLATE
      - !delete
        record: !variable conjur/factories/core/v1/user
      - !delete
        record: !policy conjur/factories/core
      - !delete
        record: !policy conjur/factories
      - !delete
        record: !policy conjur
    TEMPLATE

    patch('/policies/rspec/policy/root', params: base_policy, env: request_env)
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

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
            '/factory-resources/rspec/core/user',
            env: auth_headers.merge({ 'RAW_POST_DATA' => request_body })
          )

          # We're really only checking that the Factories::CreateFromPolicyFactory.call method
          # is called with expected arguements. We're testing this class separately.
          decoded_factory = JSON.parse(Base64.decode64(user_factory))
          expect(policy_creator).to have_received(:call).with({
            account: 'rspec',
            factory_template: DB::Repository::DataObjects::PolicyFactory.new(
              policy: Base64.decode64(decoded_factory['policy']),
              policy_branch: decoded_factory['policy_branch'],
              schema: decoded_factory['schema'],
              version: 'v1',
              name: 'user',
              classification: 'core'
            ),
            request_body: { id: 'test-user-1', branch: 'root' }.to_json,
            request_ip: '127.0.0.1',
            request_method: 'POST',
            role: current_user
          })
          expect(response.code).to eq('201')
          # This response is mocked. We're not really returning this in real life.
          # Tests on Factories::CreateFromPolicyFactory verify that we always receive
          # a success or failure object.
          expect(response.body).to eq('success!!')
        end
      end
    end
  end
end
