# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe PolicyFactoriesController, type: :request do
  def user_factory
    # rubocop:disable Layout/LineLength
    'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoZFhObGNnb2dJR2xrT2lBOEpUMGdhV1FnSlQ0S1BDVWdhV1lnWkdWbWFXNWxaRDhvYjNkdVpYSmZjbTlzWlNrZ0ppWWdaR1ZtYVc1bFpEOG9iM2R1WlhKZmRIbHdaU2tnTFNVK0NpQWdiM2R1WlhJNklDRThKVDBnYjNkdVpYSmZkSGx3WlNBbFBpQThKVDBnYjNkdVpYSmZjbTlzWlNBbFBnbzhKU0JsYm1RZ0xTVStDandsSUdsbUlHUmxabWx1WldRL0tHbHdYM0poYm1kbEtTQXRKVDRLSUNCeVpYTjBjbWxqZEdWa1gzUnZPaUE4SlQwZ2FYQmZjbUZ1WjJVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiVXNlciBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQ3JlYXRlcyBhIENvbmp1ciBVc2VyIiwidHlwZSI6Im9iamVjdCIsInByb3BlcnRpZXMiOnsiaWQiOnsiZGVzY3JpcHRpb24iOiJVc2VyIElEIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHVzZXIgaW50byIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfcm9sZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBDb25qdXIgUm9sZSB0aGF0IHdpbGwgb3duIHRoaXMgdXNlciIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfdHlwZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSByZXNvdXJjZSB0eXBlIG9mIHRoZSBvd25lciBvZiB0aGlzIHVzZXIiLCJ0eXBlIjoic3RyaW5nIn0sImlwX3JhbmdlIjp7ImRlc2NyaXB0aW9uIjoiTGltaXRzIHRoZSBuZXR3b3JrIHJhbmdlIHRoZSB1c2VyIGlzIGFsbG93ZWQgdG8gYXV0aGVudGljYXRlIGZyb20iLCJ0eXBlIjoic3RyaW5nIn19LCJyZXF1aXJlZCI6WyJicmFuY2giLCJpZCJdfX0='
    # rubocop:enable Layout/LineLength
  end

  def group_factory
    # rubocop:disable Layout/LineLength
    'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoWjNKdmRYQUtJQ0JwWkRvZ1BDVTlJR2xrSUNVK0Nqd2xJR2xtSUdSbFptbHVaV1EvS0c5M2JtVnlYM0p2YkdVcElDWW1JR1JsWm1sdVpXUS9LRzkzYm1WeVgzUjVjR1VwSUMwbFBnb2dJRzkzYm1WeU9pQWhQQ1U5SUc5M2JtVnlYM1I1Y0dVZ0pUNGdQQ1U5SUc5M2JtVnlYM0p2YkdVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiR3JvdXAgVGVtcGxhdGUiLCJkZXNjcmlwdGlvbiI6IkNyZWF0ZXMgYSBDb25qdXIgR3JvdXAiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJpZCI6eyJkZXNjcmlwdGlvbiI6Ikdyb3VwIElkZW50aWZpZXIiLCJ0eXBlIjoic3RyaW5nIn0sImFubm90YXRpb25zIjp7ImRlc2NyaXB0aW9uIjoiQWRkaXRpb25hbCBhbm5vdGF0aW9ucyIsInR5cGUiOiJvYmplY3QifSwiYnJhbmNoIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IGJyYW5jaCB0byBsb2FkIHRoaXMgcmVzb3VyY2UgaW50byIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfcm9sZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBDb25qdXIgUm9sZSB0aGF0IHdpbGwgb3duIHRoaXMgZ3JvdXAiLCJ0eXBlIjoic3RyaW5nIn0sIm93bmVyX3R5cGUiOnsiZGVzY3JpcHRpb24iOiJUaGUgcmVzb3VyY2UgdHlwZSBvZiB0aGUgb3duZXIgb2YgdGhpcyBncm91cCIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbImJyYW5jaCIsImlkIl19fQ=='
    # rubocop:enable Layout/LineLength
  end

  def database_factory
    # rubocop:disable Layout/LineLength
    'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0c5c2FXTjVDaUFnYVdRNklEd2xQU0JwWkNBbFBnb2dJR0Z1Ym05MFlYUnBiMjV6T2dvOEpTQmhibTV2ZEdGMGFXOXVjeTVsWVdOb0lHUnZJSHhyWlhrc0lIWmhiSFZsZkNBdEpUNEtJQ0FnSUR3bFBTQnJaWGtnSlQ0NklEd2xQU0IyWVd4MVpTQWxQZ284SlNCbGJtUWdMU1UrQ2dvZ0lHSnZaSGs2Q2lBZ0xTQW1kbUZ5YVdGaWJHVnpDaUFnSUNBdElDRjJZWEpwWVdKc1pTQjFjbXdLSUNBZ0lDMGdJWFpoY21saFlteGxJSEJ2Y25RS0lDQWdJQzBnSVhaaGNtbGhZbXhsSUhWelpYSnVZVzFsQ2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J3WVhOemQyOXlaQW9nSUNBZ0xTQWhkbUZ5YVdGaWJHVWdjM05zTFdObGNuUnBabWxqWVhSbENpQWdJQ0F0SUNGMllYSnBZV0pzWlNCemMyd3RhMlY1Q2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J6YzJ3dFkyRXRZMlZ5ZEdsbWFXTmhkR1VLQ2lBZ0xTQWhaM0p2ZFhBZ1kyOXVjM1Z0WlhKekNpQWdMU0FoWjNKdmRYQWdZV1J0YVc1cGMzUnlZWFJ2Y25NS0lDQUtJQ0FqSUdOdmJuTjFiV1Z5Y3lCallXNGdjbVZoWkNCaGJtUWdaWGhsWTNWMFpRb2dJQzBnSVhCbGNtMXBkQW9nSUNBZ2NtVnpiM1Z5WTJVNklDcDJZWEpwWVdKc1pYTUtJQ0FnSUhCeWFYWnBiR1ZuWlhNNklGc2djbVZoWkN3Z1pYaGxZM1YwWlNCZENpQWdJQ0J5YjJ4bE9pQWhaM0p2ZFhBZ1kyOXVjM1Z0WlhKekNpQWdDaUFnSXlCaFpHMXBibWx6ZEhKaGRHOXljeUJqWVc0Z2RYQmtZWFJsSUNoaGJtUWdjbVZoWkNCaGJtUWdaWGhsWTNWMFpTd2dkbWxoSUhKdmJHVWdaM0poYm5RcENpQWdMU0FoY0dWeWJXbDBDaUFnSUNCeVpYTnZkWEpqWlRvZ0tuWmhjbWxoWW14bGN3b2dJQ0FnY0hKcGRtbHNaV2RsY3pvZ1d5QjFjR1JoZEdVZ1hRb2dJQ0FnY205c1pUb2dJV2R5YjNWd0lHRmtiV2x1YVhOMGNtRjBiM0p6Q2lBZ0NpQWdJeUJoWkcxcGJtbHpkSEpoZEc5eWN5Qm9ZWE1nY205c1pTQmpiMjV6ZFcxbGNuTUtJQ0F0SUNGbmNtRnVkQW9nSUNBZ2JXVnRZbVZ5T2lBaFozSnZkWEFnWVdSdGFXNXBjM1J5WVhSdmNuTUtJQ0FnSUhKdmJHVTZJQ0ZuY205MWNDQmpiMjV6ZFcxbGNuTT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiRGF0YWJhc2UgQ29ubmVjdGlvbiBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQWxsIGluZm9ybWF0aW9uIGZvciBjb25uZWN0aW5nIHRvIGEgZGF0YWJhc2UiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJpZCI6eyJkZXNjcmlwdGlvbiI6IlJlc291cmNlIElkZW50aWZpZXIiLCJ0eXBlIjoic3RyaW5nIn0sImFubm90YXRpb25zIjp7ImRlc2NyaXB0aW9uIjoiQWRkaXRpb25hbCBhbm5vdGF0aW9ucyIsInR5cGUiOiJvYmplY3QifSwiYnJhbmNoIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IGJyYW5jaCB0byBsb2FkIHRoaXMgcmVzb3VyY2UgaW50byIsInR5cGUiOiJzdHJpbmcifSwidmFyaWFibGVzIjp7InR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7InVybCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFVSTCIsInR5cGUiOiJzdHJpbmcifSwicG9ydCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFBvcnQiLCJ0eXBlIjoic3RyaW5nIn0sInVzZXJuYW1lIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgVXNlcm5hbWUiLCJ0eXBlIjoic3RyaW5nIn0sInBhc3N3b3JkIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgUGFzc3dvcmQiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1jZXJ0aWZpY2F0ZSI6eyJkZXNjcmlwdGlvbiI6IkNsaWVudCBTU0wgQ2VydGlmaWNhdGUiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1rZXkiOnsiZGVzY3JpcHRpb24iOiJDbGllbnQgU1NMIEtleSIsInR5cGUiOiJzdHJpbmcifSwic3NsLWNhLWNlcnRpZmljYXRlIjp7ImRlc2NyaXB0aW9uIjoiQ0EgUm9vdCBDZXJ0aWZpY2F0ZSIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbInVybCIsInBvcnQiLCJ1c2VybmFtZSIsInBhc3N3b3JkIl19fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwiaWQiLCJ2YXJpYWJsZXMiXX19'
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
            - !variable v1/group
            - !variable v1/user

          - !policy
            id: connections
            annotations:
              description: "Create connections to external services"
            body:
            - !variable v1/database
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
      'core/v1/group' => group_factory,
      'core/v1/user' => user_factory,
      'connections/v1/database' => database_factory
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
        record: !variable conjur/factories/core/v1/group
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
          expect(result['core'].length).to eq(2)
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
            'message' => 'Role does not have permission to use Factories, or, no Factories are available'
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
        'required' => %w[branch id]
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
end
