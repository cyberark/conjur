# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe PolicyFactoriesController, type: :request do
  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')

    # Simple Factories
    # rubocop:disable Layout/LineLength
    user_factory = 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoZFhObGNnb2dJR2xrT2lBOEpUMGdhV1FnSlQ0S1BDVWdhV1lnWkdWbWFXNWxaRDhvYjNkdVpYSmZjbTlzWlNrZ0ppWWdaR1ZtYVc1bFpEOG9iM2R1WlhKZmRIbHdaU2tnTFNVK0NpQWdiM2R1WlhJNklDRThKVDBnYjNkdVpYSmZkSGx3WlNBbFBpQThKVDBnYjNkdVpYSmZjbTlzWlNBbFBnbzhKU0JsYm1RZ0xTVStDandsSUdsbUlHUmxabWx1WldRL0tHbHdYM0poYm1kbEtTQXRKVDRLSUNCeVpYTjBjbWxqZEdWa1gzUnZPaUE4SlQwZ2FYQmZjbUZ1WjJVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiVXNlciBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQ3JlYXRlcyBhIENvbmp1ciBVc2VyIiwidHlwZSI6Im9iamVjdCIsInByb3BlcnRpZXMiOnsiaWQiOnsiZGVzY3JpcHRpb24iOiJVc2VyIElEIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHVzZXIgaW50byIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfcm9sZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBDb25qdXIgUm9sZSB0aGF0IHdpbGwgb3duIHRoaXMgdXNlciIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfdHlwZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSByZXNvdXJjZSB0eXBlIG9mIHRoZSBvd25lciBvZiB0aGlzIHVzZXIiLCJ0eXBlIjoic3RyaW5nIn0sImlwX3JhbmdlIjp7ImRlc2NyaXB0aW9uIjoiTGltaXRzIHRoZSBuZXR3b3JrIHJhbmdlIHRoZSB1c2VyIGlzIGFsbG93ZWQgdG8gYXV0aGVudGljYXRlIGZyb20iLCJ0eXBlIjoic3RyaW5nIn19LCJyZXF1aXJlZCI6WyJicmFuY2giLCJpZCJdfX0='
    group_factory = 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoWjNKdmRYQUtJQ0JwWkRvZ1BDVTlJR2xrSUNVK0Nqd2xJR2xtSUdSbFptbHVaV1EvS0c5M2JtVnlYM0p2YkdVcElDWW1JR1JsWm1sdVpXUS9LRzkzYm1WeVgzUjVjR1VwSUMwbFBnb2dJRzkzYm1WeU9pQWhQQ1U5SUc5M2JtVnlYM1I1Y0dVZ0pUNGdQQ1U5SUc5M2JtVnlYM0p2YkdVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiR3JvdXAgVGVtcGxhdGUiLCJkZXNjcmlwdGlvbiI6IkNyZWF0ZXMgYSBDb25qdXIgR3JvdXAiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJpZCI6eyJkZXNjcmlwdGlvbiI6Ikdyb3VwIElkZW50aWZpZXIiLCJ0eXBlIjoic3RyaW5nIn0sImFubm90YXRpb25zIjp7ImRlc2NyaXB0aW9uIjoiQWRkaXRpb25hbCBhbm5vdGF0aW9ucyIsInR5cGUiOiJvYmplY3QifSwiYnJhbmNoIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IGJyYW5jaCB0byBsb2FkIHRoaXMgcmVzb3VyY2UgaW50byIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfcm9sZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBDb25qdXIgUm9sZSB0aGF0IHdpbGwgb3duIHRoaXMgZ3JvdXAiLCJ0eXBlIjoic3RyaW5nIn0sIm93bmVyX3R5cGUiOnsiZGVzY3JpcHRpb24iOiJUaGUgcmVzb3VyY2UgdHlwZSBvZiB0aGUgb3duZXIgb2YgdGhpcyBncm91cCIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbImJyYW5jaCIsImlkIl19fQ=='
    policy_factory = 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0c5c2FXTjVDaUFnYVdRNklEd2xQU0JwWkNBbFBnbzhKU0JwWmlCa1pXWnBibVZrUHlodmQyNWxjbDl5YjJ4bEtTQW1KaUJrWldacGJtVmtQeWh2ZDI1bGNsOTBlWEJsS1NBdEpUNEtJQ0J2ZDI1bGNqb2dJVHdsUFNCdmQyNWxjbDkwZVhCbElDVStJRHdsUFNCdmQyNWxjbDl5YjJ4bElDVStDandsSUdWdVpDQXRKVDRLSUNCaGJtNXZkR0YwYVc5dWN6b0tQQ1VnWVc1dWIzUmhkR2x2Ym5NdVpXRmphQ0JrYnlCOGEyVjVMQ0IyWVd4MVpYd2dMU1UrQ2lBZ0lDQThKVDBnYTJWNUlDVStPaUE4SlQwZ2RtRnNkV1VnSlQ0S1BDVWdaVzVrSUMwbFBnbz0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiUG9saWN5IFRlbXBsYXRlIiwiZGVzY3JpcHRpb24iOiJDcmVhdGVzIGEgQ29uanVyIFBvbGljeSIsInR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7ImlkIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IElEIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHBvbGljeSBpbnRvIiwidHlwZSI6InN0cmluZyJ9LCJvd25lcl9yb2xlIjp7ImRlc2NyaXB0aW9uIjoiVGhlIENvbmp1ciBSb2xlIHRoYXQgd2lsbCBvd24gdGhpcyBwb2xpY3kiLCJ0eXBlIjoic3RyaW5nIn0sIm93bmVyX3R5cGUiOnsiZGVzY3JpcHRpb24iOiJUaGUgcmVzb3VyY2UgdHlwZSBvZiB0aGUgb3duZXIgb2YgdGhpcyBwb2xpY3kiLCJ0eXBlIjoic3RyaW5nIn19LCJyZXF1aXJlZCI6WyJicmFuY2giLCJpZCJdfX0='
    # Complex Factory
    database_factory = 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0c5c2FXTjVDaUFnYVdRNklEd2xQU0JwWkNBbFBnb2dJR0Z1Ym05MFlYUnBiMjV6T2dvOEpTQmhibTV2ZEdGMGFXOXVjeTVsWVdOb0lHUnZJSHhyWlhrc0lIWmhiSFZsZkNBdEpUNEtJQ0FnSUR3bFBTQnJaWGtnSlQ0NklEd2xQU0IyWVd4MVpTQWxQZ284SlNCbGJtUWdMU1UrQ2dvZ0lHSnZaSGs2Q2lBZ0xTQW1kbUZ5YVdGaWJHVnpDaUFnSUNBdElDRjJZWEpwWVdKc1pTQjFjbXdLSUNBZ0lDMGdJWFpoY21saFlteGxJSEJ2Y25RS0lDQWdJQzBnSVhaaGNtbGhZbXhsSUhWelpYSnVZVzFsQ2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J3WVhOemQyOXlaQW9nSUNBZ0xTQWhkbUZ5YVdGaWJHVWdjM05zTFdObGNuUnBabWxqWVhSbENpQWdJQ0F0SUNGMllYSnBZV0pzWlNCemMyd3RhMlY1Q2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J6YzJ3dFkyRXRZMlZ5ZEdsbWFXTmhkR1VLQ2lBZ0xTQWhaM0p2ZFhBZ1kyOXVjM1Z0WlhKekNpQWdMU0FoWjNKdmRYQWdZV1J0YVc1cGMzUnlZWFJ2Y25NS0lDQUtJQ0FqSUdOdmJuTjFiV1Z5Y3lCallXNGdjbVZoWkNCaGJtUWdaWGhsWTNWMFpRb2dJQzBnSVhCbGNtMXBkQW9nSUNBZ2NtVnpiM1Z5WTJVNklDcDJZWEpwWVdKc1pYTUtJQ0FnSUhCeWFYWnBiR1ZuWlhNNklGc2djbVZoWkN3Z1pYaGxZM1YwWlNCZENpQWdJQ0J5YjJ4bE9pQWhaM0p2ZFhBZ1kyOXVjM1Z0WlhKekNpQWdDaUFnSXlCaFpHMXBibWx6ZEhKaGRHOXljeUJqWVc0Z2RYQmtZWFJsSUNoaGJtUWdjbVZoWkNCaGJtUWdaWGhsWTNWMFpTd2dkbWxoSUhKdmJHVWdaM0poYm5RcENpQWdMU0FoY0dWeWJXbDBDaUFnSUNCeVpYTnZkWEpqWlRvZ0tuWmhjbWxoWW14bGN3b2dJQ0FnY0hKcGRtbHNaV2RsY3pvZ1d5QjFjR1JoZEdVZ1hRb2dJQ0FnY205c1pUb2dJV2R5YjNWd0lHRmtiV2x1YVhOMGNtRjBiM0p6Q2lBZ0NpQWdJeUJoWkcxcGJtbHpkSEpoZEc5eWN5Qm9ZWE1nY205c1pTQmpiMjV6ZFcxbGNuTUtJQ0F0SUNGbmNtRnVkQW9nSUNBZ2JXVnRZbVZ5T2lBaFozSnZkWEFnWVdSdGFXNXBjM1J5WVhSdmNuTUtJQ0FnSUhKdmJHVTZJQ0ZuY205MWNDQmpiMjV6ZFcxbGNuTT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiRGF0YWJhc2UgQ29ubmVjdGlvbiBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQWxsIGluZm9ybWF0aW9uIGZvciBjb25uZWN0aW5nIHRvIGEgZGF0YWJhc2UiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJpZCI6eyJkZXNjcmlwdGlvbiI6IlJlc291cmNlIElkZW50aWZpZXIiLCJ0eXBlIjoic3RyaW5nIn0sImFubm90YXRpb25zIjp7ImRlc2NyaXB0aW9uIjoiQWRkaXRpb25hbCBhbm5vdGF0aW9ucyIsInR5cGUiOiJvYmplY3QifSwiYnJhbmNoIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IGJyYW5jaCB0byBsb2FkIHRoaXMgcmVzb3VyY2UgaW50byIsInR5cGUiOiJzdHJpbmcifSwidmFyaWFibGVzIjp7InR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7InVybCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFVSTCIsInR5cGUiOiJzdHJpbmcifSwicG9ydCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFBvcnQiLCJ0eXBlIjoic3RyaW5nIn0sInVzZXJuYW1lIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgVXNlcm5hbWUiLCJ0eXBlIjoic3RyaW5nIn0sInBhc3N3b3JkIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgUGFzc3dvcmQiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1jZXJ0aWZpY2F0ZSI6eyJkZXNjcmlwdGlvbiI6IkNsaWVudCBTU0wgQ2VydGlmaWNhdGUiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1rZXkiOnsiZGVzY3JpcHRpb24iOiJDbGllbnQgU1NMIEtleSIsInR5cGUiOiJzdHJpbmcifSwic3NsLWNhLWNlcnRpZmljYXRlIjp7ImRlc2NyaXB0aW9uIjoiQ0EgUm9vdCBDZXJ0aWZpY2F0ZSIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbInVybCIsInBvcnQiLCJ1c2VybmFtZSIsInBhc3N3b3JkIl19fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwiaWQiLCJ2YXJpYWJsZXMiXX19'
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
            - !variable v1/group
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
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fcore%2Fv1%2Fgroup', params: group_factory, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fcore%2Fv1%2Fpolicy', params: policy_factory, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fconnections%2Fv1%2Fdatabase', params: database_factory, env: request_env)
  end

  after(:all) do
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

  def request_env(role: 'admin')
    {
      'HTTP_AUTHORIZATION' => access_token_for(role)
    }
  end

  describe 'GET #index' do
    context 'when role is permitted' do
      it 'retrieves all policy factories' do
        get('/factories/rspec', env: request_env)
        response_json = JSON.parse(response.body)

        expect(response_json).to eq({
          "connections" => [
            {
              "name" => "database",
              "full-name" => "connections/database",
              "description" => "All information for connecting to a database",
              "namespace" => "connections",
              "current-version" => "v1"
            }
          ],
          "core" => [
            {
              "current-version" => "v1",
              "description" => "Creates a Conjur Group",
              "full-name" => "core/group",
              "name" => "group",
              "namespace" => "core"
            },
            {
              "current-version" => "v1",
              "description" => "Creates a Conjur Policy",
              "full-name" => "core/policy",
              "name" => "policy",
              "namespace" => "core"
            },
            {
              "current-version" => "v1",
              "description" => "Creates a Conjur User",
              "full-name" => "core/user",
              "name" => "user",
              "namespace" => "core"
            }
          ]
        })
      end
    end
  end
  describe 'GET #show' do
    context 'when role is permitted' do
      context 'when the factory is "simple"' do
        it 'retrieves the details for a policy factory' do
          get('/factories/rspec/core/v1/user', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response_json).to eq({
            "title" => "User Template",
            "version" => "v1",
            "description" => "Creates a Conjur User",
            "properties" => {
              "annotations" => {
                "description" => "Additional annotations",
                "type" => "object"
              },
              "branch" => {
                "description" => "Policy branch to load this user into",
                "type" => "string"
              },
              "id" => {
                "description" => "User ID",
                "type" => "string"
              },
              "ip_range" => {
                "description" => "Limits the network range the user is allowed to authenticate from",
                "type" => "string"
              },
              "owner_role" => {
                "description" => "The Conjur Role that will own this user",
                "type" => "string"
              },
              "owner_type" => {
                "description" => "The resource type of the owner of this user",
                "type" => "string"
              }
            },
            "required" => %w[branch id]
          })
        end
      end
      context 'when the factory is "complex"' do
        it 'retrieves the details for a policy factory' do
          get('/factories/rspec/connections/v1/database', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response_json).to eq({
            "title" => "Database Connection Template",
            "version" => "v1",
            "description" => "All information for connecting to a database",
            "properties" => {
              "id" => {
                "description" => "Resource Identifier",
                "type" => "string"
              },
              "branch" => {
                "description" => "Policy branch to load this resource into",
                "type" => "string"
              },
              "annotations" => {
                "description" => "Additional annotations",
                "type" => "object"
              },
              "variables" => {
                "properties" => {
                  "url" => {
                    "description" => "Database URL",
                    "type" => "string"
                  },
                  "username" => {
                    "description" => "Database Username",
                    "type" => "string"
                  },
                  "password" => {
                    "description" => "Database Password",
                    "type" => "string"
                  },
                  "port" => {
                    "description" => "Database Port",
                    "type" => "string"
                  },
                  "ssl-ca-certificate" => {
                    "description" => "CA Root Certificate",
                    "type" => "string"
                  },
                  "ssl-certificate" => {
                    "description" => "Client SSL Certificate",
                    "type" => "string"
                  },
                  "ssl-key" => {
                    "description" => "Client SSL Key",
                    "type" => "string"
                  }
                },
                "required" => %w[url port username password],
                "type" => "object"
              }
            },
            "required" => %w[branch id variables]
          })
        end
      end
    end
  end
end
