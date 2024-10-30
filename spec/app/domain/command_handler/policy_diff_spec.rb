# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(CommandHandler::PolicyDiff) do
  let(:created_diff_response) do
    ::SuccessResponse.new(
      DB::Repository::DataObjects::DiffElements.new(
        diff_type: 'created',
        annotations: [],
        permissions: [],
        resources: [],
        role_memberships: [],
        roles: [],
        credentials: []
      )
    )
  end

  let(:deleted_diff_response) do
    ::SuccessResponse.new(
      DB::Repository::DataObjects::DiffElements.new(
        diff_type: 'deleted',
        annotations: [],
        permissions: [],
        resources: [],
        role_memberships: [],
        roles: [],
        credentials: []
      )
    )
  end

  let(:updated_diff_response) do
    ::SuccessResponse.new(
      DB::Repository::DataObjects::DiffElements.new(
        diff_type: 'updated',
        annotations: [],
        permissions: [],
        resources: [],
        role_memberships: [],
        roles: [],
        credentials: []
      )
    )
  end

  let(:db) do
    double('Database').tap do |mock|
      allow(mock).to receive(:execute).with(anything).and_return(nil)
      allow(mock).to receive(:fetch).with(anything).and_return([])
      allow(mock).to receive(:search_path=).with(anything)
    end
  end

  let(:policy_repository) do
    instance_double('DB::Repository::PolicyRepository').tap do |repo|
      allow(repo).to receive(:find_created_elements)
        .with(anything)
        .and_return(created_diff_response)
      allow(repo).to receive(:find_deleted_elements)
        .with(anything)
        .and_return(deleted_diff_response)
      allow(repo).to receive(:find_original_elements)
        .with(anything)
        .and_return(updated_diff_response)
    end
  end

  let(:policy_diff) do
    CommandHandler::PolicyDiff.new(policy_repository: policy_repository)
  end

  describe '.call' do
    let(:diff_schema_name) { 'policy_loader_before_abcdefg' }

    it 'returns a response containing a diff' do
      response = policy_diff.call(diff_schema_name: diff_schema_name)
      expect(response.success?).to eq(true)
      expect(response.result[:created])
        .to be_a(DB::Repository::DataObjects::DiffElements)
      expect(response.result[:deleted])
        .to be_a(DB::Repository::DataObjects::DiffElements)
      expect(response.result[:updated])
        .to be_a(DB::Repository::DataObjects::DiffElements)
      expect(response.result[:final])
        .to be_a(DB::Repository::DataObjects::DiffElements)
    end
  end

  describe '#filter' do
    let(:whitelist) do
      {
        "cucumber:user:bob" => true
      }
    end

    context 'when given a list of elements without a resource_id, role_id, or member_id' do
      let(:elements) do
        [
          {
            random_key: "random value"
          }
        ]
      end

      it 'returns an empty list' do
        response = policy_diff.send(:filter_elements, elements, whitelist)
        expect(response).to be_a(Array)
        expect(response).to be_a(Array)
        expect(response.length).to eq(0)
      end
    end

    context 'when given a list of annotations' do
      let(:elements) do
        [
          {
            resource_id: "cucumber:user:alice",
            name: "description",
            value: "This is an annotation for alice",
            policy_id: "cucumber:policy:root"
          },
          {
            resource_id: "cucumber:user:bob",
            name: "description",
            value: "This is an annotation for bob",
            policy_id: "cucumber:policy:root"
          }
        ]
      end

      it 'returns whitelisted items based on resource_id' do
        response = policy_diff.send(:filter_elements, elements, whitelist)
        expect(response).to be_a(Array)
        expect(response.length).to eq(1)
        expect(response[0][:resource_id]).to eq("cucumber:user:bob")
      end
    end

    context 'when given a list of resources' do
      let(:elements) do
        [
          {
            resource_id: "cucumber:user:alice",
            owner_id: "cucumber:policy:example",
            policy_id: "cucumber:policy:root"
          },
          {
            resource_id: "cucumber:user:bob",
            owner_id: "cucumber:policy:example",
            policy_id: "cucumber:policy:root"
          }
        ]
      end

      it 'returns whitelisted items based on resource_id' do
        response = policy_diff.send(:filter_elements, elements, whitelist)
        expect(response).to be_a(Array)
        expect(response.length).to eq(1)
        expect(response[0][:resource_id]).to eq("cucumber:user:bob")
      end
    end

    context 'when given a list of credentials' do
      let(:elements) do
        [
          {
            role_id: "cucumber:user:alice",
            client_id: nil,
            restricted_to: []
          },
          {
            role_id: "cucumber:user:bob",
            client_id: nil,
            restricted_to: []
          }
        ]
      end

      it 'returns whitelisted items based on role_id' do
        response = policy_diff.send(:filter_elements, elements, whitelist)
        expect(response).to be_a(Array)
        expect(response.length).to eq(1)
        expect(response[0][:role_id]).to eq("cucumber:user:bob")
      end
    end

    context 'when given a list of permissions' do
      let(:elements) do
        [
          {
            "privilege": "create",
            "resource_id": "cucumber:variable:example/secret01",
            "role_id": "cucumber:user:alice",
            "policy_id": "cucumber:policy:root"
          },
          {
            "privilege": "create",
            "resource_id": "cucumber:variable:example/secret01",
            "role_id": "cucumber:user:bob",
            "policy_id": "cucumber:policy:root"
          }
        ]
      end

      context 'when the whitelist contains role_ids' do
        it 'returns whitelisted items based on role_id' do
          response = policy_diff.send(:filter_elements, elements, whitelist)
          expect(response).to be_a(Array)
          expect(response.length).to eq(1)
          expect(response[0][:role_id]).to eq("cucumber:user:bob")
        end
      end

      context 'when the whitelist contains resource_ids' do
        let(:whitelist) do
          {
            "cucumber:variable:example/secret01" => true
          }
        end
        it 'returns whitelisted items based on resource_id' do
          response = policy_diff.send(:filter_elements, elements, whitelist)
          expect(response).to be_a(Array)
          expect(response.length).to eq(2)
          expect(response[0][:resource_id]).to eq("cucumber:variable:example/secret01")
          expect(response[1][:resource_id]).to eq("cucumber:variable:example/secret01")
        end
      end
    end

    context 'when given a list of role memberships' do
      let(:elements) do
        [
          {
            "role_id": "cucumber:user:alice",
            "member_id": "cucumber:policy:example",
            "admin_option": true,
            "ownership": true,
            "policy_id": "cucumber:policy:root"
          },
          {
            "role_id": "cucumber:user:bob",
            "member_id": "cucumber:policy:example",
            "admin_option": true,
            "ownership": true,
            "policy_id": "cucumber:policy:root"
          }
        ]
      end

      context 'when the whitelist contains role_ids' do
        it 'returns whitelisted items based on role_id' do
          response = policy_diff.send(:filter_elements, elements, whitelist)
          expect(response).to be_a(Array)
          expect(response.length).to eq(1)
          expect(response[0][:role_id]).to eq("cucumber:user:bob")
        end
      end

      context 'when the whitelist contains member_ids' do
        let(:whitelist) do
          {
            "cucumber:policy:example" => true
          }
        end
        it 'returns whitelisted items based on member_id' do
          response = policy_diff.send(:filter_elements, elements, whitelist)
          expect(response).to be_a(Array)
          expect(response.length).to eq(2)
          expect(response[0][:member_id]).to eq("cucumber:policy:example")
          expect(response[1][:member_id]).to eq("cucumber:policy:example")
        end
      end
    end
  end

  describe '#find_updated_elements' do
    let(:created_diff_elements) do
      DB::Repository::DataObjects::DiffElements.new(
        diff_type: 'created',
        annotations: [],
        permissions: [],
        resources: [],
        role_memberships: [],
        roles: [],
        credentials: []
      )
    end

    let(:deleted_diff_elements) do
      DB::Repository::DataObjects::DiffElements.new(
        diff_type: 'deleted',
        annotations: [],
        permissions: [],
        resources: [],
        role_memberships: [],
        roles: [],
        credentials: []
      )
    end

    let(:updated_diff_elements) do
      DB::Repository::DataObjects::DiffElements.new(
        diff_type: 'updated',
        annotations: [],
        permissions: [],
        resources: [
          {
            resource_id: "cucumber:user:barrett@example",
            owner_id: "cucumber:policy:example",
            policy_id: "cucumber:policy:root"
          }
        ],
        role_memberships: [],
        roles: [],
        credentials: []
      )
    end

    context 'when updating a resource' do
      context 'to include a new annotation, permission, membership, and credential' do
        let(:created_diff_elements) do
          DB::Repository::DataObjects::DiffElements.new(
            diff_type: 'created',
            annotations: [
              {
                resource_id: "cucumber:user:barrett@example",
                name: "key",
                value: "value",
                policy_id: "cucumber:policy:root"
              }
            ],
            permissions: [
              {
                privilege: "update",
                resource_id: "cucumber:variable:example/secret01",
                role_id: "cucumber:user:barrett@example",
                policy_id: "cucumber:policy:root"
              }
            ],
            resources: [],
            role_memberships: [
              {
                role_id: "cucumber:group:example/secret-users",
                member_id: "cucumber:user:barrett@example",
                admin_option: false,
                ownership: false,
                policy_id: "cucumber:policy:root"
              }
            ],
            roles: [],
            credentials: [
              {
                role_id: "cucumber:user:barrett@example",
                client_id: nil,
                restricted_to: ["127.0.0.1"]
              }
            ]
          )
        end
    
        it 'the final diff contains the new annotation' do
          updated_resource_ids = updated_diff_elements.resources.each_with_object({}) do |resource, hash|
            hash[resource[:resource_id]] = true
          end
          response = policy_diff.send(:find_updated_elements, created_diff_elements, deleted_diff_elements, updated_diff_elements, updated_resource_ids)
          expect(response).to be_a(DB::Repository::DataObjects::DiffElements)
          expect(response.diff_type).to eq('final')
          expect(updated_diff_elements.annotations.length).to eq(0)
          expect(response.annotations.length).to eq(1)
          expect(response.annotations[0][:name]).to eq('key')
          expect(response.annotations[0][:value]).to eq('value')

          expect(updated_diff_elements.permissions.length).to eq(0)
          expect(response.permissions.length).to eq(1)
          expect(response.permissions[0][:privilege]).to eq('update')
          expect(response.permissions[0][:resource_id]).to eq('cucumber:variable:example/secret01')
          expect(response.permissions[0][:role_id]).to eq('cucumber:user:barrett@example')
          expect(response.permissions[0][:policy_id]).to eq('cucumber:policy:root')

          expect(updated_diff_elements.role_memberships.length).to eq(0)
          expect(response.role_memberships.length).to eq(1)
          expect(response.role_memberships[0][:role_id]).to eq('cucumber:group:example/secret-users')
          expect(response.role_memberships[0][:member_id]).to eq('cucumber:user:barrett@example')
          expect(response.role_memberships[0][:admin_option]).to eq(false)
          expect(response.role_memberships[0][:ownership]).to eq(false)
          expect(response.role_memberships[0][:policy_id]).to eq('cucumber:policy:root')

          expect(updated_diff_elements.credentials.length).to eq(0)
          expect(response.credentials.length).to eq(1)
          expect(response.credentials[0][:role_id]).to eq('cucumber:user:barrett@example')
          expect(response.credentials[0][:client_id]).to eq(nil)
          expect(response.credentials[0][:restricted_to]).to eq(["127.0.0.1"])
        end
      end
      
      context 'to delete an existing annotation, permission, membership, and credential' do
        let(:updated_diff_elements) do
          DB::Repository::DataObjects::DiffElements.new(
            diff_type: 'updated',
            annotations: [
              {
                resource_id: "cucumber:user:barrett@example",
                name: "first",
                value: "the first annotation",
                policy_id: "cucumber:policy:root"
              },
              {
                resource_id: "cucumber:user:barrett@example",
                name: "second",
                value: "the second annotation",
                policy_id: "cucumber:policy:root"
              }
            ],
            permissions: [
              {
                privilege: "update",
                resource_id: "cucumber:variable:example/secret01",
                role_id: "cucumber:user:barrett@example",
                policy_id: "cucumber:policy:root"
              },
              {
                privilege: "update",
                resource_id: "cucumber:variable:example/secret02",
                role_id: "cucumber:user:barrett@example",
                policy_id: "cucumber:policy:root"
              }
            ],
            resources: [
              {
                resource_id: "cucumber:user:barrett@example",
                owner_id: "cucumber:policy:example",
                policy_id: "cucumber:policy:root"
              }
            ],
            role_memberships: [
              {
                role_id: "cucumber:group:example/secret-admins",
                member_id: "cucumber:user:barrett@example",
                admin_option: false,
                ownership: false,
                policy_id: "cucumber:policy:root"
              },
              {
                role_id: "cucumber:group:example/secret-users",
                member_id: "cucumber:user:barrett@example",
                admin_option: false,
                ownership: false,
                policy_id: "cucumber:policy:root"
              }
            ],
            roles: [],
            credentials: [
              {
                role_id: "cucumber:user:barrett@example",
                client_id: nil,
                restricted_to: ["127.0.0.1"]
              }
            ]
          )
        end

        let(:deleted_diff_elements) do
          DB::Repository::DataObjects::DiffElements.new(
            diff_type: 'deleted',
            annotations: [
              {
                resource_id: "cucumber:user:barrett@example",
                name: "second",
                value: "the second annotation",
                policy_id: "cucumber:policy:root"
              }
            ],
            permissions: [
              {
                privilege: "update",
                resource_id: "cucumber:variable:example/secret01",
                role_id: "cucumber:user:barrett@example",
                policy_id: "cucumber:policy:root"
              }
            ],
            resources: [],
            role_memberships: [
              {
                role_id: "cucumber:group:example/secret-admins",
                member_id: "cucumber:user:barrett@example",
                admin_option: false,
                ownership: false,
                policy_id: "cucumber:policy:root"
              }
            ],
            roles: [],
            credentials: [
              {
                role_id: "cucumber:user:barrett@example",
                client_id: nil,
                restricted_to: ["127.0.0.1"]
              }
            ]
          )
        end
    
        it 'the final diff preserves the existing elements but does not include the deleted elements' do
          updated_resource_ids = updated_diff_elements.resources.each_with_object({}) do |resource, hash|
            hash[resource[:resource_id]] = true
          end
          response = policy_diff.send(:find_updated_elements, created_diff_elements, deleted_diff_elements, updated_diff_elements, updated_resource_ids)
          expect(response).to be_a(DB::Repository::DataObjects::DiffElements)
          expect(response.diff_type).to eq('final')
          expect(updated_diff_elements.annotations.length).to eq(2)
          expect(response.annotations.length).to eq(1)
          expect(response.annotations[0][:name]).to eq('first')
          expect(response.annotations[0][:value]).to eq('the first annotation')

          expect(updated_diff_elements.permissions.length).to eq(2)
          expect(response.permissions.length).to eq(1)
          expect(response.permissions[0][:privilege]).to eq('update')
          expect(response.permissions[0][:resource_id]).to eq('cucumber:variable:example/secret02')
          expect(response.permissions[0][:role_id]).to eq('cucumber:user:barrett@example')
          expect(response.permissions[0][:policy_id]).to eq('cucumber:policy:root')

          expect(updated_diff_elements.role_memberships.length).to eq(2)
          expect(response.role_memberships.length).to eq(1)
          expect(response.role_memberships[0][:role_id]).to eq('cucumber:group:example/secret-users')
          expect(response.role_memberships[0][:member_id]).to eq('cucumber:user:barrett@example')
          expect(response.role_memberships[0][:admin_option]).to eq(false)
          expect(response.role_memberships[0][:ownership]).to eq(false)
          expect(response.role_memberships[0][:policy_id]).to eq('cucumber:policy:root')

          expect(updated_diff_elements.credentials.length).to eq(1)
          expect(response.credentials.length).to eq(0)
        end
      end

      context 'to delete a newly created annotation, permission, membership, and credential' do
        let(:created_diff_elementsq) do
          DB::Repository::DataObjects::DiffElements.new(
            diff_type: 'updated',
            annotations: [
              {
                resource_id: "cucumber:user:barrett@example",
                name: "first",
                value: "the first annotation",
                policy_id: "cucumber:policy:root"
              }
            ],
            permissions: [
              {
                privilege: "update",
                resource_id: "cucumber:variable:example/secret01",
                role_id: "cucumber:user:barrett@example",
                policy_id: "cucumber:policy:root"
              }
            ],
            resources: [],
            role_memberships: [
              {
                role_id: "cucumber:group:example/secret-admins",
                member_id: "cucumber:user:barrett@example",
                admin_option: false,
                ownership: false,
                policy_id: "cucumber:policy:root"
              }
            ],
            roles: [],
            credentials: [
              {
                role_id: "cucumber:user:barrett@example",
                client_id: nil,
                restricted_to: ["127.0.0.1"]
              }
            ]
          )
        end

        let(:deleted_diff_elements) do
          DB::Repository::DataObjects::DiffElements.new(
            diff_type: 'deleted',
            annotations: [
              {
                resource_id: "cucumber:user:barrett@example",
                name: "first",
                value: "the first annotation",
                policy_id: "cucumber:policy:root"
              }
            ],
            permissions: [
              {
                privilege: "update",
                resource_id: "cucumber:variable:example/secret01",
                role_id: "cucumber:user:barrett@example",
                policy_id: "cucumber:policy:root"
              }
            ],
            resources: [],
            role_memberships: [
              {
                role_id: "cucumber:group:example/secret-admins",
                member_id: "cucumber:user:barrett@example",
                admin_option: false,
                ownership: false,
                policy_id: "cucumber:policy:root"
              }
            ],
            roles: [],
            credentials: [
              {
                role_id: "cucumber:user:barrett@example",
                client_id: nil,
                restricted_to: ["127.0.0.1"]
              }
            ]
          )
        end

        let(:updated_diff_elements) do
          DB::Repository::DataObjects::DiffElements.new(
            diff_type: 'updated',
            annotations: [
              {
                resource_id: "cucumber:user:barrett@example",
                name: "existing annotation",
                value: "this should remain",
                policy_id: "cucumber:policy:root"
              }
            ],
            permissions: [
              {
                privilege: "update",
                resource_id: "cucumber:variable:example/existing-variable",
                role_id: "cucumber:user:barrett@example",
                policy_id: "cucumber:policy:root"
              }
            ],
            resources: [
              {
                resource_id: "cucumber:user:barrett@example",
                owner_id: "cucumber:policy:example",
                policy_id: "cucumber:policy:root"
              },
              {
                resource_id: "cucumber:user:alice@example",
                owner_id: "cucumber:policy:example",
                policy_id: "cucumber:policy:root"
              }
            ],
            role_memberships: [
              {
                role_id: "cucumber:group:example/existing-group",
                member_id: "cucumber:user:barrett@example",
                admin_option: false,
                ownership: false,
                policy_id: "cucumber:policy:root"
              }
            ],
            roles: [],
            credentials: [
              {
                role_id: "cucumber:user:alice@example",
                client_id: nil,
                restricted_to: ["127.0.0.1"]
              }
            ]
          )
        end

        # Deletions are applied after resources and their attributes are created
        # just like in a normal policy load. This is an edge case, as creating
        # and deleting the same resource in the same policy operation is not
        # valid policy
        it 'the final diff preserves the existing elements but does not include the created elements' do
          updated_resource_ids = updated_diff_elements.resources.each_with_object({}) do |resource, hash|
            hash[resource[:resource_id]] = true
          end
          response = policy_diff.send(:find_updated_elements, created_diff_elements, deleted_diff_elements, updated_diff_elements, updated_resource_ids)
          expect(response).to be_a(DB::Repository::DataObjects::DiffElements)
          expect(response.diff_type).to eq('final')
          expect(updated_diff_elements.annotations.length).to eq(1)
          expect(response.annotations.length).to eq(1)
          expect(response.annotations[0][:name]).to eq('existing annotation')
          expect(response.annotations[0][:value]).to eq('this should remain')

          expect(updated_diff_elements.permissions.length).to eq(1)
          expect(response.permissions.length).to eq(1)
          expect(response.permissions[0][:privilege]).to eq('update')
          expect(response.permissions[0][:resource_id]).to eq('cucumber:variable:example/existing-variable')
          expect(response.permissions[0][:role_id]).to eq('cucumber:user:barrett@example')
          expect(response.permissions[0][:policy_id]).to eq('cucumber:policy:root')

          expect(updated_diff_elements.role_memberships.length).to eq(1)
          expect(response.role_memberships.length).to eq(1)
          expect(response.role_memberships[0][:role_id]).to eq('cucumber:group:example/existing-group')
          expect(response.role_memberships[0][:member_id]).to eq('cucumber:user:barrett@example')
          expect(response.role_memberships[0][:admin_option]).to eq(false)
          expect(response.role_memberships[0][:ownership]).to eq(false)
          expect(response.role_memberships[0][:policy_id]).to eq('cucumber:policy:root')

          expect(updated_diff_elements.credentials.length).to eq(1)
          expect(response.credentials.length).to eq(1)
          expect(response.credentials[0][:role_id]).to eq('cucumber:user:alice@example')
          expect(response.credentials[0][:client_id]).to eq(nil)
          expect(response.credentials[0][:restricted_to]).to eq(["127.0.0.1"])
        end
      end
    end
  end
end
