# frozen_string_literal: true

require 'spec_helper'

# This test has been observed to leave resources from
# the 'rootpolicy' that interfered with other tests.
# Two approaches have been added to clean those up:
# - Instead of simply forcing :truncation strategy, the existing
#   DatabaseCleaner strategy is saved, then set to :truncation
#   for this test, then restored upon exit
# - Also before exit, an empty base policy is applied to root branch.
#
# DatabaseCleaner.strategy = :truncation

describe PoliciesController, type: :request do
  before(:all) do
    # there doesn't seem to be a sane way to get this
    @original_database_cleaner_strategy =
      DatabaseCleaner.connections.first.strategy
        .class.name.downcase[/[^:]+$/].intern

    # we need truncation here because the tests span many transactions
    DatabaseCleaner.strategy = :truncation

    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')

    base_policy = <<~TEMPLATE
      - !policy
        id: rootpolicy
        body:
          []
    TEMPLATE

    user_policy = <<~TEMPLATE
      - !user rot
    TEMPLATE

    policy_acme = <<~TEMPLATE
      - !policy
        id: acme-adm
        annotations:
          description: Policy acme in root made by admin
          type: acme-adm-type
        body:
          - !user ali
          - !user ala
          - !user ale
          - !user alo
          - !user aly
      
          - !grant
            role: !user ali
            members:
              - !user ../../rot
      
          - !policy
            id: outer-adm
            owner: !user ali
            body:
              - !user bob
      
              - !group grp-outer-adm
      
              - !grant
                role: !group grp-outer-adm
                members:
                  - !user ../ali
                  - !user ../ala
                  - !user ../ale
                  - !user ../alo
                  - !user ../aly
      
              - !grant
                role: !user bob
                members:
                  - !user ../ali
      
              - !permit
                role: !group grp-outer-adm
                privileges: [ read, execute ]
                resource: !policy inner-adm
      
              - !permit
                role: !user bob
                privileges: [read, update, create]
                resource: !policy inner-adm
      
              - !policy
                id: root
                body:
                  - !user usr
      
              - !policy
                id: inner-adm
                owner: !user bob
                body:
                  - !variable
                    id: inner-adm-var1
                    kind: description
                    mime_type: text/plain
                    annotations:
                      description: Desc for var 2 in inner-adm
                  - !variable
                    id: inner-adm-var2
                    kind: description
                    mime_type: text/plain
                    annotations:
                      description: Desc for var 2 in inner-adm
      
                  - !user cac
      
                  - !policy
                    id: data-adm
                    body:
                      - !variable inner-data-adm-var1
                      - !variable
                        id: inner-data-adm-var2
                        kind: description
                        mime_type: text/plain
                        annotations:
                          description: Desc for var 2 in inner-adm
      
                      - !webservice inner-data-adm-ws1
                      - !webservice
                        id: inner-data-adm-ws2
                        annotations:
                          description: Desc for var 2 in inner-adm
                      - !webservice
                        id: inner-data-adm-ws3
                        owner: !policy /rootpolicy/acme-adm/outer-adm/inner-adm/data-adm
      
                      - !layer data-adm-lyr1
                      - !layer
                        id: data-adm-lyr2
      
                      - !host data-adm-hst1
                      - !host
                        id: data-adm-hst2
      
                      - !host-factory
                        id: data-adm-hf1
                        layers: [ !layer data-adm-lyr1 ]
      
                      - !host-factory
                        id: data-adm-hf2
                        owner: !host data-adm-hst2
                        layers: [ !layer data-adm-lyr1, !layer data-adm-lyr2 ]
                        annotations:
                          description: annotation description
      
                      - !group data-adm-grp1
                      - !group
                        id: data-adm-grp2
                        owner: !host-factory data-adm-hf2
                        annotations:
                          description: annotation description
      
          - !policy
            id: outer-adm-inner-adm
            body:
              - !variable hole/nope/hn-var1
              - !variable hole/nope/nope/hnn-var2
              - !variable hole/nope/nope/nope/hnnn-var3
              - !policy hole/nope/hn-pol1
      
          - !host
            id: outer-host
            owner: !policy outer-adm-inner-adm
      
          - !policy
            id: outer
            body:
              - !policy
                id: adm
                body:
                  - !policy
                    id: inner
                    body:
                    - !policy
                      id: adm
                      body:
                        []
    TEMPLATE

    post('/policies/rspec/policy/root', params: base_policy, env: request_env)
    patch('/policies/rspec/policy/root', params: user_policy, env: request_env)
    patch('/policies/rspec/policy/rootpolicy', params: policy_acme, env: request_env)
  end

  after(:all) do
    # base_policy = <<~TEMPLATE
    #   - !delete
    #     record: !variable conjur/factories/core/v1/user
    #   - !delete
    #     record: !variable conjur/factories/core/v1/policy
    #   - !delete
    #     record: !policy conjur/factories/core
    #   - !delete
    #     record: !policy conjur/factories/connections
    #   - !delete
    #     record: !policy conjur/factories
    #   - !delete
    #     record: !policy conjur
    # TEMPLATE
    #
    # patch('/policies/rspec/policy/root', params: base_policy, env: request_env)

    base_policy = <<~TEMPLATE
      #
    TEMPLATE
    put('/policies/rspec/policy/root', params: base_policy, env: request_env)

    DatabaseCleaner.strategy = @original_database_cleaner_strategy
  end

  def request_env(role: 'admin')
    {
      'HTTP_AUTHORIZATION' => access_token_for(role)
    }
  end

  describe '#get' do
    context 'when fetching policy' do
      context 'when a policy does not exist' do
        it 'returns not found' do
          get('/policies/rspec/policy/some/not/existing/policy', env: request_env)

          response_json = JSON.parse(response.body)

          expect(response.status).to eq(404)
          expect(response_json).to eq({
            "error"=> {
              "code" => "not_found",
              "details" => {
                "code" => "not_found",
                "message" => "rspec:policy:some/not/existing/policy",
                "target" => "id"
              },
              "message" => "Policy 'some/not/existing/policy' not found in account 'rspec'",
              "target"=>"policy"
            }
          })
        end
      end

      context 'when provided string instead of number for limit' do
        it 'returns bad request' do
          get('/policies/rspec/policy/rootpolicy?limit=asdf', env: request_env)

          expect(response.status).to eq(400)
        end
      end

      context 'when the value of limit is over maximum value from configuration' do
        it 'returns bad request' do
          get('/policies/rspec/policy/rootpolicy?limit=10000000', env: request_env)

          expect(response.status).to eq(400)
        end
      end

      context 'when the value of limit is below the minimal value from configuration' do
        it 'returns bad request' do
          get('/policies/rspec/policy/rootpolicy?limit=-2', env: request_env)

          expect(response.status).to eq(400)
        end
      end

      context 'when provided string instead of number for depth' do
        it 'returns bad request' do
          get('/policies/rspec/policy/rootpolicy?depth=asdf', env: request_env)

          expect(response.status).to eq(400)
        end
      end

      context 'when the value of depth is over the maximum value from configuration' do
        it 'returns bad request' do
          get('/policies/rspec/policy/rootpolicy?depth=10000000', env: request_env)

          expect(response.status).to eq(400)
        end
      end

      context 'when the value of depth is below the minimal value from configuration' do
        it 'returns bad request' do
          get('/policies/rspec/policy/rootpolicy?depth=-2', env: request_env)

          expect(response.status).to eq(400)
        end
      end

      context 'when trying to get with limit less than policy count' do
        it 'returns unprocessable entity' do
          get('/policies/rspec/policy/rootpolicy?limit=2', env: request_env)

          response_json = JSON.parse(response.body)

          expect(response.status).to eq(422)
          expect(response_json).to eq({
            "error" => {
              "code" => "unprocessable_entity",
              "message" => "CONJ00164E Policy max allowed 'limit' = 2 exceeded. Value for policy is: 51"
            }
          })
        end
      end

      context 'when trying to get not policy in url' do
        it 'returns bad request' do
          get('/policies/rspec/user/rootpolicy', env: request_env)
          expect(response.status).to eq(400)
        end
      end
    end
  end
end
