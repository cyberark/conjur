# frozen_string_literal: true

require 'base64'

module Factories
  module Templates
    module Core
      module V1
        class Grant
          class << self
            def policy_template
              <<~TEMPLATE
                - !grant
                  member: !<%= member_resource_type %> <%= member_resource_id %>
                  role: !<%= role_resource_type %> <%= role_resource_id %>
              TEMPLATE
            end

            def data
              Base64.encode64({
                version: 1,
                policy: Base64.encode64(policy_template),
                policy_branch: "<%= branch %>",
                schema: {
                  "$schema": "http://json-schema.org/draft-06/schema#",
                  "title": "Grant Template",
                  "description": "Assigns a Role to another Role",
                  "type": "object",
                  "properties": {
                    "branch": {
                      "description": "Policy branch to load this grant into",
                      "type": "string"
                    },
                    "member_resource_type": {
                      "description": "The member type (group, host, user, etc.) for the grant",
                      "type": "string"
                    },
                    "member_resource_id": {
                      "description": "The member resource identifier for the grant",
                      "type": "string"
                    },
                    "role_resource_type": {
                      "description": "The role type (group, host, user, etc.) for the grant",
                      "type": "string"
                    },
                    "role_resource_id": {
                      "description": "The role resource identifier for the grant",
                      "type": "string"
                    }
                  },
                  "required": %w[branch member_resource_type member_resource_id role_resource_type role_resource_id]
                }
              }.to_json)
            end
          end
        end
      end
    end
  end
end
