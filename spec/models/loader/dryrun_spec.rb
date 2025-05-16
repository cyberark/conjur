# frozen_string_literal: true

require 'spec_helper'
require 'spec_helper_policy'

# Test outline:
# Verify shape of response to these dry-run policy submissions:
# - Invalid policy
# - Validate successful policy
#   - create
#   - update
#   - replace

# Not an empty file, but devoid of policy statements
basic_policy =
  <<~YAML
    #
  YAML

# Just a simple parse error, anything to cause policy invalid
bad_policy =
  <<~YAML
    - !!str, xxx
  YAML

bare_response =
  <<~EXPECTED.gsub(/\n/, '')
    {
    "status":"Valid YAML",
    "created":{
    "items":[]
    },
    "updated":{
    "before":{
    "items":[]
    },
    "after":{
    "items":[]
    }
    },
    "deleted":{
    "items":[]
    }
    }
  EXPECTED

def validation_status
  body = JSON.parse(response.body)
  body['status']
end

def validation_error_text
  body = JSON.parse(response.body)
  message = body['errors'][0]['message']
  message.match(/^(.*)\n*$/).to_s
end

describe PoliciesController, type: :request do
  context 'dryrun a policy with invalid syntax' do
    it 'returns only status and error, no dry-run fields' do
      validate_policy(
        action: :put,
        policy: bad_policy
      )
      expect(response.code).to eq("422")
      expect(validation_status).to match("Invalid YAML")
      expect(validation_error_text).to match(/did not find expected whitespace or line break/)
    end
  end

  context 'Valid Policy #put' do
    it 'returns status and a complete, but empty, dry-run response structure' do
      validate_policy(
        action: :put,
        policy: basic_policy
      )
      puts JSON.pretty_generate(response.body)
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(bare_response)
      expect(validation_status).to match("Valid YAML")
    end
  end

  context 'Valid Policy #patch' do
    it 'returns status and a complete, but empty, dry-run response structure' do
      validate_policy(
        action: :patch,
        policy: basic_policy
      )
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(bare_response)
      expect(validation_status).to match("Valid YAML")
    end
  end

  context 'Valid Policy #post' do
    it 'returns status and a complete, but empty, dry-run response structure' do
      validate_policy(
        action: :post,
        policy: basic_policy
      )
      expect(response.code).to match(/20\d/)
      expect(response.body).to eq(bare_response)
      expect(validation_status).to match("Valid YAML")
    end
  end

  context 'dryrun a policy to create new resources' do
    let(:base_policy) do
      <<~YAML
        - !policy
          id: example
          body:
            - !user
              id: barrett
              restricted_to: [ "127.0.0.1" ]
              annotations:
                key: value
            - !host
              id: server01
              restricted_to: [ "127.0.0.1" ]
              annotations:
                key: value
            - !group
              id: users
              annotations:
                key: value
            - !layer
              id: servers
              annotations:
                key: value
            - !variable
              id: secret01
              annotations:
                key: value
            - !webservice
              id: service01
              annotations:
                key: value
      YAML
    end

    it 'creates new resources' do
      validate_policy(
        action: :post,
        policy: base_policy
      )
      expect(response.code).to match(/20\d/)

      json_response = JSON.parse(response.body)
      created_items_hash = json_response["created"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

      # Assert the number of changed items
      expect(json_response["status"]).to match("Valid YAML")
      expect(json_response["created"]["items"].length).to be(7)
      expect(json_response["updated"]["before"]["items"].length).to be(0)
      expect(json_response["updated"]["after"]["items"].length).to be(0)
      expect(json_response["deleted"]["items"].length).to be(0)

      # Assert the properties and values on each resource
      # We'll assert the full interface on a single role and resource below
      target_resource = "rspec:user:barrett@example"
      target_resource_index = created_items_hash[target_resource]
      expect(created_items_hash).to have_key(target_resource)
      expect(json_response["created"]["items"][target_resource_index]["annotations"]).to have_key("key")
      expect(json_response["created"]["items"][target_resource_index]["annotations"]["key"]).to eq("value")
      expect(json_response["created"]["items"][target_resource_index]["id"]).to eq("barrett@example")
      expect(json_response["created"]["items"][target_resource_index]["identifier"]).to eq("rspec:user:barrett@example")
      expect(json_response["created"]["items"][target_resource_index]["members"]).to eq(["rspec:policy:example"])
      expect(json_response["created"]["items"][target_resource_index]["memberships"]).to eq([])
      expect(json_response["created"]["items"][target_resource_index]["owner"]).to eq("rspec:policy:example")
      expect(json_response["created"]["items"][target_resource_index]["permissions"]).to eq({})
      expect(json_response["created"]["items"][target_resource_index]["policy"]).to eq("rspec:policy:root")
      expect(json_response["created"]["items"][target_resource_index]["type"]).to eq("user")
      expect(json_response["created"]["items"][target_resource_index]["restricted_to"]).to eq(["127.0.0.1/32"])

      target_resource = "rspec:host:example/server01"
      target_resource_index = created_items_hash[target_resource]
      expect(created_items_hash).to have_key(target_resource)
      expect(json_response["created"]["items"][target_resource_index]["annotations"]).to have_key("key")
      expect(json_response["created"]["items"][target_resource_index]["annotations"]["key"]).to eq("value")
      expect(json_response["created"]["items"][target_resource_index]["restricted_to"]).to eq(["127.0.0.1/32"])

      target_resource = "rspec:group:example/users"
      target_resource_index = created_items_hash[target_resource]
      expect(created_items_hash).to have_key(target_resource)
      expect(json_response["created"]["items"][target_resource_index]["annotations"]).to have_key("key")
      expect(json_response["created"]["items"][target_resource_index]["annotations"]["key"]).to eq("value")

      target_resource = "rspec:layer:example/servers"
      target_resource_index = created_items_hash[target_resource]
      expect(created_items_hash).to have_key(target_resource)
      expect(json_response["created"]["items"][target_resource_index]["annotations"]).to have_key("key")
      expect(json_response["created"]["items"][target_resource_index]["annotations"]["key"]).to eq("value")

      target_resource = "rspec:variable:example/secret01"
      target_resource_index = created_items_hash[target_resource]
      expect(created_items_hash).to have_key(target_resource)
      expect(json_response["created"]["items"][target_resource_index]["annotations"]).to have_key("key")
      expect(json_response["created"]["items"][target_resource_index]["annotations"]["key"]).to eq("value")
      expect(json_response["created"]["items"][target_resource_index]["id"]).to eq("example/secret01")
      expect(json_response["created"]["items"][target_resource_index]["identifier"]).to eq("rspec:variable:example/secret01")
      expect(json_response["created"]["items"][target_resource_index]["owner"]).to eq("rspec:policy:example")
      expect(json_response["created"]["items"][target_resource_index]["permitted"]).to eq({})
      expect(json_response["created"]["items"][target_resource_index]["policy"]).to eq("rspec:policy:root")
      expect(json_response["created"]["items"][target_resource_index]["type"]).to eq("variable")

      target_resource = "rspec:webservice:example/service01"
      target_resource_index = created_items_hash[target_resource]
      expect(created_items_hash).to have_key(target_resource)
      expect(json_response["created"]["items"][target_resource_index]["annotations"]).to have_key("key")
      expect(json_response["created"]["items"][target_resource_index]["annotations"]["key"]).to eq("value")
    end
  end

  context 'dryrun a policy with various updates' do
    let(:base_policy) do
      <<~YAML
        - !policy
          id: example
          body:
            - !user
              id: barrett
            - !group
              id: secret-users
            - !variable
              id: secret01
              annotations:
                key: value
      YAML
    end

    before(:each) do
      apply_policy(
        action: :put,
        policy: base_policy
      )
    end

    context 'update a role annotations' do
      let(:dryrun_policy) do
        <<~YAML
          - !policy
            id: example
            body:
              - !user
                id: barrett
                annotations:
                  key: value
        YAML
      end

      it 'returns a role with new annotations' do
        validate_policy(
          action: :patch,
          policy: dryrun_policy
        )
        expect(response.code).to match(/20\d/)

        json_response = JSON.parse(response.body)
        updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
        updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

        # Assert the number of changed items
        expect(json_response["status"]).to match("Valid YAML")
        expect(json_response["created"]["items"].length).to be(0)
        expect(json_response["updated"]["before"]["items"].length).to be(1)
        expect(json_response["updated"]["after"]["items"].length).to be(1)
        expect(json_response["deleted"]["items"].length).to be(0)

        # Assert the properties and values on each resource
        target_resource = "rspec:user:barrett@example"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["annotations"]).to eq({})

        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["after"]["items"][target_resource_index]["annotations"]).to have_key("key")
        expect(json_response["updated"]["after"]["items"][target_resource_index]["annotations"]["key"]).to eq("value")
      end
    end

    context 'dryrun a policy that adds restricted_to to a role' do
      let(:dryrun_policy) do
        <<~YAML
          - !policy
            id: example
            body:
              - !user
                id: barrett
                restricted_to: [ "127.0.0.1" ]
        YAML
      end

      it 'returns a role with a new restricted_to' do
        validate_policy(
          action: :patch,
          policy: dryrun_policy
        )
        expect(response.code).to match(/20\d/)

        json_response = JSON.parse(response.body)
        updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
        updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

        # Assert the number of changed items
        expect(json_response["status"]).to match("Valid YAML")
        expect(json_response["created"]["items"].length).to be(0)
        expect(json_response["updated"]["before"]["items"].length).to be(1)
        expect(json_response["updated"]["after"]["items"].length).to be(1)
        expect(json_response["deleted"]["items"].length).to be(0)

        # Assert the properties and values on each resource
        target_resource = "rspec:user:barrett@example"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["restricted_to"]).to eq([])

        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["after"]["items"][target_resource_index]["restricted_to"]).to eq(["127.0.0.1/32"])
      end
    end

    context 'grant an existing user membership to an existing role and permit the role to a resource' do
      let(:dryrun_policy) do
        <<~YAML
          - !policy
            id: example
            body:
              - !grant
                role: !group secret-users
                member: !user barrett
              - !permit
                role: !group secret-users
                privileges: [ read, execute ]
                resources:
                  - !variable secret01
        YAML
      end

      it 'returns roles with new members, memberships, and permissions' do
        validate_policy(
          action: :patch,
          policy: dryrun_policy
        )
        json_response = JSON.parse(response.body)
        puts JSON.pretty_generate(json_response)
        expect(response.code).to match(/20\d/)

        updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
        updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

        # Assert the number of changed items
        expect(json_response["status"]).to match("Valid YAML")
        expect(json_response["created"]["items"].length).to be(0)
        expect(json_response["updated"]["before"]["items"].length).to be(3)
        expect(json_response["updated"]["after"]["items"].length).to be(3)
        expect(json_response["deleted"]["items"].length).to be(0)

        # Assert the properties and values on each resource
        target_resource = "rspec:user:barrett@example"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["memberships"]).to eq([])

        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["after"]["items"][target_resource_index]["memberships"]).to eq(["rspec:group:example/secret-users"])

        target_resource = "rspec:variable:example/secret01"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["permitted"]).to eq({})

        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["after"]["items"][target_resource_index]["permitted"]).to match({
          "execute" => contain_exactly("rspec:group:example/secret-users"),
          "read" => contain_exactly("rspec:group:example/secret-users")
        })

        target_resource = "rspec:group:example/secret-users"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq(["rspec:policy:example"])
        expect(json_response["updated"]["before"]["items"][target_resource_index]["permissions"]).to eq({})

        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["after"]["items"][target_resource_index]["members"]).to eq([
          "rspec:policy:example",
          "rspec:user:barrett@example"
        ])
        expect(json_response["updated"]["after"]["items"][target_resource_index]["permissions"]).to match({
          "execute" => contain_exactly("rspec:variable:example/secret01"),
          "read" => contain_exactly("rspec:variable:example/secret01")
        })
      end
    end

    context 'update permissions on an existing resource to an existing role' do
      let(:dryrun_policy) do
        <<~YAML
          - !policy
            id: example
            body:
              - !permit
                role: !group secret-users
                privileges: [ update ]
                resources:
                  - !variable secret01

        YAML
      end

      it 'returns roles and resources with updated permissions' do
        validate_policy(
          action: :patch,
          policy: dryrun_policy
        )
        expect(response.code).to match(/20\d/)

        json_response = JSON.parse(response.body)
        updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
        updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

        # Assert the number of changed items
        expect(json_response["status"]).to match("Valid YAML")
        expect(json_response["created"]["items"].length).to be(0)
        expect(json_response["updated"]["before"]["items"].length).to be(2)
        expect(json_response["updated"]["after"]["items"].length).to be(2)
        expect(json_response["deleted"]["items"].length).to be(0)

        # Assert the properties and values on each resource
        target_resource = "rspec:variable:example/secret01"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["permitted"]).to eq({})

        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["after"]["items"][target_resource_index]["permitted"]).to match({
          "update" => contain_exactly("rspec:group:example/secret-users")
        })

        target_resource = "rspec:group:example/secret-users"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq(["rspec:policy:example"])
        expect(json_response["updated"]["before"]["items"][target_resource_index]["permissions"]).to eq({})

        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["after"]["items"][target_resource_index]["members"]).to eq([
          "rspec:policy:example"
        ])
        expect(json_response["updated"]["after"]["items"][target_resource_index]["permissions"]).to match({
          "update" => contain_exactly("rspec:variable:example/secret01")
        })
      end
    end

    context 'delete the policy' do
      let(:dryrun_policy) do
        <<~YAML
          - !delete
            record: !policy example
        YAML
      end

      context 'when using PATCH' do
        let(:http_method) { :patch }

        it 'deletes the roles and resources and the policy itself' do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)
          deleted_items_hash = json_response["deleted"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(0)
          expect(json_response["updated"]["after"]["items"].length).to be(0)
          expect(json_response["deleted"]["items"].length).to be(4)

          # Assert these resources are deleted
          target_resource = "rspec:variable:example/secret01"
          expect(deleted_items_hash).to have_key(target_resource)

          target_resource = "rspec:user:barrett@example"
          expect(deleted_items_hash).to have_key(target_resource)

          target_resource = "rspec:group:example/secret-users"
          expect(deleted_items_hash).to have_key(target_resource)

          target_resource = "rspec:policy:example"
          expect(deleted_items_hash).to have_key(target_resource)
        end
      end

      context 'when using PUT' do
        let(:http_method) { :put }

        it 'deletes the roles and resources and the policy itself' do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)
          deleted_items_hash = json_response["deleted"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(0)
          expect(json_response["updated"]["after"]["items"].length).to be(0)
          expect(json_response["deleted"]["items"].length).to be(4)

          # Assert these resources are deleted
          target_resource = "rspec:variable:example/secret01"
          expect(deleted_items_hash).to have_key(target_resource)

          target_resource = "rspec:user:barrett@example"
          expect(deleted_items_hash).to have_key(target_resource)

          target_resource = "rspec:group:example/secret-users"
          expect(deleted_items_hash).to have_key(target_resource)

          target_resource = "rspec:policy:example"
          expect(deleted_items_hash).to have_key(target_resource)
        end
      end
    end
  end

  context 'dryrun a policy to delete resources' do
    let(:base_policy) do
      <<~YAML
        - !policy
          id: example
          body:
            - !user alice
            - !host server01
            - !group users
            - !layer servers
            - !webservice service01
            - !variable secret01
      YAML
    end

    before(:each) do
      apply_policy(
        action: :put,
        policy: base_policy
      )
    end

    context 'when using PATCH' do
      let(:http_method) { :patch }

      context 'when deleting a user' do
        let(:dryrun_policy) do
          <<~YAML
            - !policy
              id: example
              body:
                - !delete
                  record: !user alice
          YAML
        end

        it 'the user is deleted'  do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(1)
          expect(json_response["updated"]["after"]["items"].length).to be(1)
          expect(json_response["deleted"]["items"].length).to be(1)

          # Asert the properties and values on the updated resources
          expect(json_response["updated"]["before"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["before"]["items"][0]["memberships"]).to eq([
            "rspec:group:example/users",
            "rspec:host:example/server01",
            "rspec:layer:example/servers",
            "rspec:user:alice@example"
          ])
          expect(json_response["updated"]["after"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["after"]["items"][0]["memberships"]).to eq([
            "rspec:group:example/users",
            "rspec:host:example/server01",
            "rspec:layer:example/servers"
          ])

          # Asert the properties and values on the deleted resource
          expect(json_response["deleted"]["items"][0]["identifier"]).to eq("rspec:user:alice@example")
        end
      end

      context 'when deleting a host' do
        let(:dryrun_policy) do
          <<~YAML
            - !policy
              id: example
              body:
                - !delete
                  record: !host server01
          YAML
        end

        it 'the host is deleted'  do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)
          puts JSON.pretty_generate(json_response)

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(1)
          expect(json_response["updated"]["after"]["items"].length).to be(1)
          expect(json_response["deleted"]["items"].length).to be(1)

          # Asert the properties and values on the updated resources
          expect(json_response["updated"]["before"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["before"]["items"][0]["memberships"]).to eq([
            "rspec:group:example/users",
            "rspec:host:example/server01",
            "rspec:layer:example/servers",
            "rspec:user:alice@example"
          ])
          expect(json_response["updated"]["after"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["after"]["items"][0]["memberships"]).to eq([
            "rspec:group:example/users",
            "rspec:layer:example/servers",
            "rspec:user:alice@example"
          ])

          # Asert the properties and values on the deleted resource
          expect(json_response["deleted"]["items"][0]["identifier"]).to eq("rspec:host:example/server01")
        end
      end

      context 'when deleting a group' do
        let(:dryrun_policy) do
          <<~YAML
            - !policy
              id: example
              body:
                - !delete
                  record: !group users
          YAML
        end

        it 'the group is deleted'  do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(1)
          expect(json_response["updated"]["after"]["items"].length).to be(1)
          expect(json_response["deleted"]["items"].length).to be(1)

          # Asert the properties and values on the updated resources
          expect(json_response["updated"]["before"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["before"]["items"][0]["memberships"]).to eq([
            "rspec:group:example/users",
            "rspec:host:example/server01",
            "rspec:layer:example/servers",
            "rspec:user:alice@example"
          ])
          expect(json_response["updated"]["after"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["after"]["items"][0]["memberships"]).to eq([
            "rspec:host:example/server01",
            "rspec:layer:example/servers",
            "rspec:user:alice@example"
          ])

          # Asert the properties and values on the deleted resource
          expect(json_response["deleted"]["items"][0]["identifier"]).to eq("rspec:group:example/users")
        end
      end

      context 'when deleting a layer' do
        let(:dryrun_policy) do
          <<~YAML
            - !policy
              id: example
              body:
                - !delete
                  record: !layer servers
          YAML
        end

        it 'the layer is deleted'  do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(1)
          expect(json_response["updated"]["after"]["items"].length).to be(1)
          expect(json_response["deleted"]["items"].length).to be(1)

          # Asert the properties and values on the updated resources
          expect(json_response["updated"]["before"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["before"]["items"][0]["memberships"]).to eq([
            "rspec:group:example/users",
            "rspec:host:example/server01",
            "rspec:layer:example/servers",
            "rspec:user:alice@example"
          ])
          expect(json_response["updated"]["after"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["after"]["items"][0]["memberships"]).to eq([
            "rspec:group:example/users",
            "rspec:host:example/server01",
            "rspec:user:alice@example"
          ])

          # Asert the properties and values on the deleted resource
          expect(json_response["deleted"]["items"][0]["identifier"]).to eq("rspec:layer:example/servers")
        end
      end

      context 'when deleting a variable' do
        let(:dryrun_policy) do
          <<~YAML
            - !policy
              id: example
              body:
                - !delete
                  record: !variable secret01
          YAML
        end

        it 'the variable is deleted'  do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(0)
          expect(json_response["updated"]["after"]["items"].length).to be(0)
          expect(json_response["deleted"]["items"].length).to be(1)

          # Asert the properties and values on the deleted resource
          expect(json_response["deleted"]["items"][0]["identifier"]).to eq("rspec:variable:example/secret01")
        end
      end

      context 'when deleting a webservice' do
        let(:dryrun_policy) do
          <<~YAML
            - !policy
              id: example
              body:
                - !delete
                  record: !webservice service01
          YAML
        end

        it 'the webservice is deleted'  do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(0)
          expect(json_response["updated"]["after"]["items"].length).to be(0)
          expect(json_response["deleted"]["items"].length).to be(1)

          # Asert the properties and values on the deleted resource
          expect(json_response["deleted"]["items"][0]["identifier"]).to eq("rspec:webservice:example/service01")
        end
      end

      context 'when deleting a policy' do
        let(:dryrun_policy) do
          <<~YAML
            - !delete
              record: !policy example
          YAML
        end

        it 'the policy and its resources are deleted'  do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          expect(response.code).to match(/20\d/)

          json_response = JSON.parse(response.body)

          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(0)
          expect(json_response["updated"]["after"]["items"].length).to be(0)
          expect(json_response["deleted"]["items"].length).to be(7)

          # Asert the properties and values on the deleted resource
          deleted_items_hash = json_response["deleted"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
          expect(deleted_items_hash).to have_key("rspec:group:example/users")
          expect(deleted_items_hash).to have_key("rspec:host:example/server01")
          expect(deleted_items_hash).to have_key("rspec:layer:example/servers")
          expect(deleted_items_hash).to have_key("rspec:policy:example")
          expect(deleted_items_hash).to have_key("rspec:user:alice@example")
          expect(deleted_items_hash).to have_key("rspec:variable:example/secret01")
          expect(deleted_items_hash).to have_key("rspec:webservice:example/service01")
        end
      end
    end

    context 'when using PUT' do
      let(:http_method) { :put }

      context 'when replacing a policy with an empty policy' do
        let(:dryrun_policy) do
          <<~YAML
            - !policy
              id: example
              body: []
          YAML
        end

        it 'the policy is updated and its resources are deleted' do
          validate_policy(
            action: http_method,
            policy: dryrun_policy
          )
          json_response = JSON.parse(response.body)
          puts JSON.pretty_generate(json_response)
          expect(response.code).to match(/20\d/)


          # Assert the number of changed items
          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(0)
          expect(json_response["updated"]["before"]["items"].length).to be(1)
          expect(json_response["updated"]["after"]["items"].length).to be(1)
          expect(json_response["deleted"]["items"].length).to be(6)

          # Asert the properties and values on the updated resource
          expect(json_response["updated"]["before"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["before"]["items"][0]["memberships"]).to eq([
            "rspec:group:example/users",
            "rspec:host:example/server01",
            "rspec:layer:example/servers",
            "rspec:user:alice@example"
          ])
          expect(json_response["updated"]["after"]["items"][0]["identifier"]).to eq("rspec:policy:example")
          expect(json_response["updated"]["after"]["items"][0]["memberships"]).to eq([])

          # Asert the properties and values on the deleted resource
          deleted_items_hash = json_response["deleted"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
          expect(deleted_items_hash).to have_key("rspec:group:example/users")
          expect(deleted_items_hash).to have_key("rspec:host:example/server01")
          expect(deleted_items_hash).to have_key("rspec:layer:example/servers")
          expect(deleted_items_hash).to have_key("rspec:user:alice@example")
          expect(deleted_items_hash).to have_key("rspec:variable:example/secret01")
          expect(deleted_items_hash).to have_key("rspec:webservice:example/service01")
        end
      end
    end
  end

  context 'dryrun a policy with change of ownership' do
    let(:base_policy) do
      <<~YAML
        - !policy
          id: example
          body:
            - !variable
              id: secret01
      YAML
    end

    context 'when using PATCH' do
      let(:http_method) { :patch }
      let(:update_ownership_policy) do
        <<~YAML
          - !user alice
          - !policy
            id: example
            owner: !user alice
            body:
              - !variable
                id: secret01
        YAML
      end

      it 'returns a policy updated with a new owner' do
        # Apply the base policy
        apply_policy(
          action: :post,
          policy: base_policy
        )
        expect(response.code).to match(/20\d/)

        # TODO: do same test for put
        # Note: this test fails on role_memberships (admin is included when they shouldn't be)
        # for put as well.
        validate_policy(
          action: http_method,
          policy: update_ownership_policy
        )
        # json_response = JSON.parse(response.body)
        # puts JSON.pretty_generate(json_response)
        json_response = JSON.parse(response.body)
        puts JSON.pretty_generate(json_response)
        expect(response.code).to match(/20\d/)

        created_items_hash = json_response["created"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
        updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
        updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

        # Assert the number of changed items
        expect(json_response["status"]).to match("Valid YAML")
        expect(json_response["created"]["items"].length).to be(1)
        expect(json_response["updated"]["before"]["items"].length).to be(1)
        expect(json_response["updated"]["after"]["items"].length).to be(1)
        expect(json_response["deleted"]["items"].length).to be(0)

        # Assert things about alice
        target_resource = "rspec:user:alice"
        expect(created_items_hash).to have_key(target_resource)
        expect(json_response["created"]["items"][created_items_hash[target_resource]]["members"]).to eq(["rspec:user:[REDACTED]"])

        # Assert that the policy owner was changed
        target_resource = "rspec:policy:example"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["created"]["items"][target_resource_index]["members"]).to eq(["rspec:user:[REDACTED]"])
        expect(json_response["created"]["items"][target_resource_index]["owner"]).to eq("rspec:user:[REDACTED]")

        # TODO: Fix this, admin user is showing up in here still?
        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq(["rspec:user:[REDACTED]"])
        expect(json_response["updated"]["after"]["items"][target_resource_index]["members"]).to eq(["rspec:user:alice"])
      end
    end

    context 'when using PUT' do
      let(:http_method) { :put }
      let(:update_ownership_policy) do
        <<~YAML
          - !user
            id: alice
          - !policy
            id: example
            owner: !user alice
            body:
              - !variable
                id: secret01
        YAML
      end

      it 'returns a policy updated with a new owner' do
        # Apply the base policy
        apply_policy(
          action: :post,
          policy: base_policy
        )
        json_response = JSON.parse(response.body)
        puts JSON.pretty_generate(json_response)
        expect(response.code).to match(/20\d/)

        # TODO: do same test for put
        # Note: this test fails on role_memberships (admin is included when they shouldn't be)
        # for put as well.
        validate_policy(
          action: http_method,
          policy: update_ownership_policy
        )
        # json_response = JSON.parse(response.body)
        # puts JSON.pretty_generate(json_response)
        json_response = JSON.parse(response.body)
        puts JSON.pretty_generate(json_response)
        expect(response.code).to match(/20\d/)

        created_items_hash = json_response["created"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
        updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
        updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

        # Assert the number of changed items
        expect(json_response["status"]).to match("Valid YAML")
        expect(json_response["created"]["items"].length).to be(1)
        expect(json_response["updated"]["before"]["items"].length).to be(1)
        expect(json_response["updated"]["after"]["items"].length).to be(1)
        expect(json_response["deleted"]["items"].length).to be(0)

        # Assert things about alice
        target_resource = "rspec:user:alice"
        expect(created_items_hash).to have_key(target_resource)
        expect(json_response["created"]["items"][created_items_hash[target_resource]]["members"]).to eq(["rspec:user:[REDACTED]"])

        # Assert that the policy owner was changed
        target_resource = "rspec:policy:example"
        target_resource_index = updated_before_items_hash[target_resource]
        expect(updated_before_items_hash).to have_key(target_resource)
        expect(json_response["created"]["items"][target_resource_index]["members"]).to eq(["rspec:user:[REDACTED]"])
        expect(json_response["created"]["items"][target_resource_index]["owner"]).to eq("rspec:user:[REDACTED]")

        # TODO: Fix this, admin user is showing up in here still?
        target_resource_index = updated_after_items_hash[target_resource]
        expect(updated_after_items_hash).to have_key(target_resource)
        expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq(["rspec:user:[REDACTED]"])
        expect(json_response["updated"]["after"]["items"][target_resource_index]["members"]).to eq(["rspec:user:alice"])
      end
    end
  end

  context 'dryrun a policy that revokes a users membership to a group' do
    let(:base_policy) do
      <<~YAML
        - !policy
          id: example
          body:
            - !user barrett
            - !group secret-users
            - !variable secret01
            - !grant
              role: !group secret-users
              member: !user barrett
            - !permit
              role: !group secret-users
              privileges: [ read, execute ]
              resources:
                - !variable secret01
      YAML
    end

    let(:dryrun_policy) do
      <<~YAML
        - !policy
          id: example
          body:
            - !revoke
              role: !group secret-users
              member: !user barrett
      YAML
    end

    it 'updates only the user and the group' do
      # Apply the base policy
      apply_policy(
        action: :post,
        policy: base_policy
      )
      expect(response.code).to match(/20\d/)

      validate_policy(
        action: :patch,
        policy: dryrun_policy
      )
      expect(response.code).to match(/20\d/)

      json_response = JSON.parse(response.body)
      updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

      # Assert the number of changed items
      expect(json_response["status"]).to match("Valid YAML")
      expect(json_response["created"]["items"].length).to be(0)
      expect(json_response["updated"]["before"]["items"].length).to be(2)
      expect(json_response["updated"]["after"]["items"].length).to be(2)
      expect(json_response["deleted"]["items"].length).to be(0)

      # Assert things about the changed resources
      target_resource = "rspec:user:barrett@example"
      target_resource_index = updated_after_items_hash[target_resource]
      expect(updated_after_items_hash).to have_key(target_resource)
      expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq(["rspec:policy:example"])
      expect(json_response["updated"]["before"]["items"][target_resource_index]["memberships"]).to eq(["rspec:group:example/secret-users"])
      expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq(["rspec:policy:example"])
      expect(json_response["updated"]["after"]["items"][target_resource_index]["memberships"]).to eq([])

      target_resource = "rspec:group:example/secret-users"
      target_resource_index = updated_after_items_hash[target_resource]
      expect(updated_after_items_hash).to have_key(target_resource)
      expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq(["rspec:policy:example", "rspec:user:barrett@example"])
      expect(json_response["updated"]["before"]["items"][target_resource_index]["permissions"]).to match({
        "execute" => contain_exactly("rspec:variable:example/secret01"),
        "read" => contain_exactly("rspec:variable:example/secret01")
      })
      expect(json_response["updated"]["after"]["items"][target_resource_index]["members"]).to eq(["rspec:policy:example"])
      expect(json_response["updated"]["after"]["items"][target_resource_index]["permissions"]).to match({
        "execute" => contain_exactly("rspec:variable:example/secret01"),
        "read" => contain_exactly("rspec:variable:example/secret01")
      })
    end
  end

  context 'dryrun a policy that denies the execute permission from a group' do
    let(:base_policy) do
      <<~YAML
        - !policy
          id: example
          body:
            - !user barrett
            - !group secret-users
            - !variable secret01
            - !grant
              role: !group secret-users
              member: !user barrett
            - !permit
              role: !group secret-users
              privileges: [ read, execute ]
              resources:
                - !variable secret01
      YAML
    end

    let(:dryrun_policy) do
      <<~YAML
        - !policy
          id: example
          body:
          - !deny
            resource: !variable secret01
            privileges: [ execute ]
            role: !group secret-users
      YAML
    end

    it 'updates only the resource and group' do
      # Apply the base policy
      apply_policy(
        action: :post,
        policy: base_policy
      )
      expect(response.code).to match(/20\d/)

      validate_policy(
        action: :patch,
        policy: dryrun_policy
      )
      expect(response.code).to match(/20\d/)

      json_response = JSON.parse(response.body)
      updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
      updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

      # Assert the number of changed items
      expect(json_response["status"]).to match("Valid YAML")
      expect(json_response["created"]["items"].length).to be(0)
      expect(json_response["updated"]["before"]["items"].length).to be(2)
      expect(json_response["updated"]["after"]["items"].length).to be(2)
      expect(json_response["deleted"]["items"].length).to be(0)

      # Assert things about the changed resources
      target_resource = "rspec:group:example/secret-users"
      target_resource_index = updated_before_items_hash[target_resource]
      expect(updated_before_items_hash).to have_key(target_resource)
      expect(json_response["updated"]["before"]["items"][target_resource_index]["permissions"]).to match({
        "execute" => contain_exactly("rspec:variable:example/secret01"),
        "read" => contain_exactly("rspec:variable:example/secret01")
      })
      expect(json_response["updated"]["after"]["items"][target_resource_index]["permissions"]).to match({
        "read" => contain_exactly("rspec:variable:example/secret01")
      })

      target_resource = "rspec:variable:example/secret01"
      target_resource_index = updated_after_items_hash[target_resource]
      expect(updated_after_items_hash).to have_key(target_resource)
      expect(json_response["updated"]["before"]["items"][target_resource_index]["permitted"]).to match({
        "execute" => contain_exactly("rspec:group:example/secret-users"),
        "read" => contain_exactly("rspec:group:example/secret-users")
      })
      expect(json_response["updated"]["after"]["items"][target_resource_index]["permitted"]).to match({
        "read" => contain_exactly("rspec:group:example/secret-users")
      })
    end
  end

  # There are edge cases where the role that executes a dryrun may see
  # details about Roles/Resources that they should not normally be able to see.
  #
  # For example
  #
  # 1. If a resource is not explicitly visible to the user, the object should be
  #    masked
  # 2. If they've updated a group, they need to be informed that the
  #    group was updated without exposing details amout references they cannot
  #    see
  #
  context 'dryrun a policy that contains masked resources' do
    context 'when roles are created by bob' do
      let(:base_policy) do
        <<~YAML
          # Bob cannot see himself
          - !user
            id: bob
          - !policy
            id: example
            body: []
          # Allow bob to manage this policy
          - !permit
            role: !user bob
            privileges: [ create, update ]
            resources: !policy example
        YAML
      end

      let(:dryrun_policy) do
        <<~YAML
          # Create a user bob can see
          - !user
            id: bob-can-see
          - !permit
            role: !user /bob
            privileges: [ read ]
            resources:
              - !user bob-can-see
          # Bob cannot see this user by default, even though he can create them
          # because he can update this policy branch
          - !user
            id: bob-cannot-see
        YAML
      end

      context "with POST" do
        let(:http_action) { :post }

        it 'the response contains only records bob can see' do
          # Apply the base policy
          apply_policy(
            action: :post,
            policy: base_policy
          )
          expect(response.code).to match(/20\d/)

          validate_policy(
            action: http_action,
            policy: dryrun_policy,
            policy_branch: "example",
            role: "bob"
          )
          json_response = JSON.parse(response.body)
          expect(response.code).to match(/20\d/)

          created_items_hash = json_response["created"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
          updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
          updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(2)
          expect(json_response["updated"]["before"]["items"].length).to be(2)
          expect(json_response["updated"]["after"]["items"].length).to be(2)
          expect(json_response["deleted"]["items"].length).to be(0)

          # Assert things about the created resources
          expect(created_items_hash).to_not have_key("rspec:user:bob-cannot-see@example")

          target_resource = "rspec:user:bob-can-see@example"
          expect(created_items_hash).to have_key(target_resource)

          target_resource = "rspec:user:[REDACTED]"
          expect(created_items_hash).to have_key(target_resource)

          # Assert things about the updated resources (before)
          target_resource = "rspec:policy:example"
          target_resource_index = updated_before_items_hash[target_resource]
          expect(updated_before_items_hash).to have_key(target_resource)
          expect(json_response["updated"]["before"]["items"][target_resource_index]["memberships"]).to eq([])

          # Assert things about the updated resources (after)
          target_resource = "rspec:policy:example"
          target_resource_index = updated_after_items_hash[target_resource]
          expect(updated_after_items_hash).to have_key(target_resource)
          expect(json_response["updated"]["after"]["items"][target_resource_index]["memberships"]).to match([
            "rspec:user:bob-can-see@example",
            "rspec:user:[REDACTED]"
          ])
        end
      end

      context "with PUT" do
        let(:http_action) { :patch }

        it 'the response contains only records bob can see' do
          # Apply the base policy
          apply_policy(
            action: :post,
            policy: base_policy
          )
          expect(response.code).to match(/20\d/)

          validate_policy(
            action: http_action,
            policy: dryrun_policy,
            policy_branch: "example",
            role: "bob"
          )
          json_response = JSON.parse(response.body)
          expect(response.code).to match(/20\d/)

          created_items_hash = json_response["created"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
          updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
          updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(2)
          expect(json_response["updated"]["before"]["items"].length).to be(2)
          expect(json_response["updated"]["after"]["items"].length).to be(2)
          expect(json_response["deleted"]["items"].length).to be(0)

          # Assert things about the created resources
          expect(created_items_hash).to_not have_key("rspec:user:bob-cannot-see@example")

          target_resource = "rspec:user:bob-can-see@example"
          expect(created_items_hash).to have_key(target_resource)

          target_resource = "rspec:user:[REDACTED]"
          expect(created_items_hash).to have_key(target_resource)

          # Assert things about the updated resources (before)
          target_resource = "rspec:policy:example"
          target_resource_index = updated_before_items_hash[target_resource]
          expect(updated_before_items_hash).to have_key(target_resource)
          expect(json_response["updated"]["before"]["items"][target_resource_index]["memberships"]).to eq([])

          # Assert things about the updated resources (after)
          target_resource = "rspec:policy:example"
          target_resource_index = updated_after_items_hash[target_resource]
          expect(updated_after_items_hash).to have_key(target_resource)
          expect(json_response["updated"]["after"]["items"][target_resource_index]["memberships"]).to match([
            "rspec:user:bob-can-see@example",
            "rspec:user:[REDACTED]"
          ])
        end
      end
    end

    context 'when a role is created with permissions on a resource' do
      let(:base_policy) do
        <<~YAML
          # Bob cannot see himself
          - !user
            id: bob
          - !policy
            id: example
            body:
            # Bob cannot see the group or resources
            - !group secret-users
            - !variable secret01
            - !permit
              role: !group secret-users
              privileges: [ read, execute ]
              resources:
                - !variable secret01
            # Allow bob to read this group
            - !permit
              role: !user /bob
              privileges: [ read ]
              resources: !group secret-users
          # Allow bob to manage this policy
          - !permit
            role: !user bob
            privileges: [ create, update ]
            resources: !policy example
        YAML
      end

      let(:dryrun_policy) do
        <<~YAML
          # Create a user bob can see
          - !user
            id: bob-can-see
          - !permit
            role: !user /bob
            privileges: [ read ]
            resources:
              - !user bob-can-see
          # Bob cannot see this user by default, even though he can create them
          # because he can update this policy branch
          - !user
            id: bob-cannot-see
          # Bob should not be able to see either group or resource in the
          # newly created users
          - !grant
            role: !group secret-users
            members:
              - !user bob-can-see
              - !user bob-cannot-see
        YAML
      end

      context "with PATCH" do
        let(:http_action) { :patch }

        it 'the response contains redacted permissions' do
          # Apply the base policy
          apply_policy(
            action: :post,
            policy: base_policy
          )
          expect(response.code).to match(/20\d/)

          validate_policy(
            action: http_action,
            policy: dryrun_policy,
            policy_branch: "example",
            role: "bob"
          )
          json_response = JSON.parse(response.body)
          expect(response.code).to match(/20\d/)

          created_items_hash = json_response["created"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
          updated_before_items_hash = json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
          updated_after_items_hash = json_response["updated"]["after"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

          expect(json_response["status"]).to match("Valid YAML")
          expect(json_response["created"]["items"].length).to be(2)
          expect(json_response["updated"]["before"]["items"].length).to be(3)
          expect(json_response["updated"]["after"]["items"].length).to be(3)
          expect(json_response["deleted"]["items"].length).to be(0)

          # Assert things about the created resources
          expect(created_items_hash).to_not have_key("rspec:user:bob-cannot-see@example")

          target_resource = "rspec:user:bob-can-see@example"
          target_resource_index = created_items_hash[target_resource]
          expect(created_items_hash).to have_key(target_resource)
          expect(json_response["created"]["items"][target_resource_index]["owner"]).to eq("rspec:policy:example")
          expect(json_response["created"]["items"][target_resource_index]["policy"]).to eq("rspec:policy:example")
          expect(json_response["created"]["items"][target_resource_index]["memberships"]).to eq(["rspec:group:example/secret-users"])

          target_resource = "rspec:user:[REDACTED]"
          target_resource_index = created_items_hash[target_resource]
          expect(created_items_hash).to have_key(target_resource)
          expect(json_response["created"]["items"][target_resource_index]).to_not have_key("id")
          expect(json_response["created"]["items"][target_resource_index]).to_not have_key("owner")
          expect(json_response["created"]["items"][target_resource_index]).to_not have_key("policy")
          expect(json_response["created"]["items"][target_resource_index]).to_not have_key("permissions")
          expect(json_response["created"]["items"][target_resource_index]).to_not have_key("annotations")
          expect(json_response["created"]["items"][target_resource_index]).to_not have_key("members")
          expect(json_response["created"]["items"][target_resource_index]).to_not have_key("memberships")
          expect(json_response["created"]["items"][target_resource_index]).to_not have_key("restricted_to")

          # Assert things about the updated resources (before)
          target_resource = "rspec:user:[REDACTED]"
          expect(updated_before_items_hash).to have_key(target_resource)

          target_resource = "rspec:group:example/secret-users"
          target_resource_index = updated_before_items_hash[target_resource]
          expect(updated_before_items_hash).to have_key(target_resource)
          expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq([
            "rspec:policy:example"
          ])
          expect(json_response["updated"]["before"]["items"][target_resource_index]["memberships"]).to eq([])
          expect(json_response["updated"]["before"]["items"][target_resource_index]["permissions"]).to match({
            "execute" => contain_exactly("rspec:variable:[REDACTED]"),
            "read" => contain_exactly("rspec:variable:[REDACTED]")
          })

          # Assert things about the updated resources (after)
          target_resource = "rspec:user:[REDACTED]"
          expect(updated_after_items_hash).to have_key(target_resource)

          target_resource = "rspec:group:example/secret-users"
          target_resource_index = updated_after_items_hash[target_resource]
          expect(updated_after_items_hash).to have_key(target_resource)
          expect(json_response["updated"]["after"]["items"][target_resource_index]["members"]).to eq([
            "rspec:policy:example",
            "rspec:user:bob-can-see@example",
            "rspec:user:[REDACTED]"
          ])
          expect(json_response["updated"]["after"]["items"][target_resource_index]["permissions"]).to match({
            "execute" => contain_exactly("rspec:variable:[REDACTED]"),
            "read" => contain_exactly("rspec:variable:[REDACTED]")
          })
        end
      end
    end

    context 'when a policy is deleted created' do
    end
  end
end
