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
  context 'Invalid Policy ' do
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

    it 'returns new resources' do
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
      expect(json_response["created"]["items"][target_resource_index]["restricted_to"]).to eq(["127.0.0.1"])

      target_resource = "rspec:host:example/server01"
      target_resource_index = created_items_hash[target_resource]
      expect(created_items_hash).to have_key(target_resource)
      expect(json_response["created"]["items"][target_resource_index]["annotations"]).to have_key("key")
      expect(json_response["created"]["items"][target_resource_index]["annotations"]["key"]).to eq("value")
      expect(json_response["created"]["items"][target_resource_index]["restricted_to"]).to eq(["127.0.0.1"])

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

    context 'dryrun a policy with annotations' do
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

    context 'dryrun a policy that adds restricted_to' do
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

      it 'returns a user with a new restricted_to' do  
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
        expect(json_response["updated"]["after"]["items"][target_resource_index]["restricted_to"]).to eq(["127.0.0.1"])
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
        expect(response.code).to match(/20\d/)

        json_response = JSON.parse(response.body)
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
            action: :patch,
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
            action: :put,
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

    let(:update_ownership_policy) do
      <<~YAML
        - !user alice
        - !policy
          id: example
          owner: !user alice
          body: []
      YAML
    end

    it 'returns a policy updated with a new owner' do
      # Dryrun the base policy
      validate_policy(
        action: :post,
        policy: base_policy
      )
      expect(response.code).to match(/20\d/)

      json_response = JSON.parse(response.body)
      created_items_hash = json_response["created"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }

      expect(json_response["status"]).to match("Valid YAML")

      # Assert these resources were created
      expect(created_items_hash).to have_key("rspec:policy:example")
      expect(created_items_hash).to have_key("rspec:variable:example/secret01")
  
      # Apply the base policy
      apply_policy(
        action: :post,
        policy: base_policy
      )
      expect(response.code).to match(/20\d/)

      validate_policy(
        action: :patch,
        policy: update_ownership_policy
      )
      expect(response.code).to match(/20\d/)

      json_response = JSON.parse(response.body)
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
      expect(json_response["created"]["items"][created_items_hash[target_resource]]["members"]).to eq(["rspec:user:admin"])

      # Assert that the policy owner was changed
      target_resource = "rspec:policy:example"
      target_resource_index = updated_before_items_hash[target_resource]
      expect(updated_before_items_hash).to have_key(target_resource)
      expect(json_response["created"]["items"][target_resource_index]["members"]).to eq(["rspec:user:admin"])
      expect(json_response["created"]["items"][target_resource_index]["owner"]).to eq("rspec:user:admin")

      target_resource_index = updated_after_items_hash[target_resource]
      expect(updated_after_items_hash).to have_key(target_resource)
      expect(json_response["updated"]["before"]["items"][target_resource_index]["members"]).to eq(["rspec:user:admin"])
      expect(json_response["updated"]["after"]["items"][target_resource_index]["members"]).to eq(["rspec:user:alice"])
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
      json_response["updated"]["before"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
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
      json_response["created"]["items"].each_with_index.to_h { |item, index| [item["identifier"], index] }
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
end
