# frozen_string_literal: true

require 'base64'

module Factories
  module Templates
    module Core
      module V1
        class Group
          class << self
            def policy_template
              <<~TEMPLATE
                - !group
                  id: <%= id %>
                <% if defined?(owner_role) && defined?(owner_type) -%>
                  owner: !<%= owner_type %> <%= owner_role %>
                <% end -%>
                  annotations:
                    factory: core/v1/group
                <% annotations.each do |key, value| -%>
                    <%= key %>: <%= value %>
                <% end -%>
              TEMPLATE
            end

            def data
              Base64.encode64({
                version: 1,
                policy: Base64.encode64(policy_template),
                policy_branch: "<%= branch %>",
                schema: {
                  "$schema": "http://json-schema.org/draft-06/schema#",
                  "title": "Group Template",
                  "description": "Creates a Conjur Group",
                  "type": "object",
                  "properties": {
                    "id": {
                      "description": "Group Identifier",
                      "type": "string"
                    },
                    "branch": {
                      "description": "Policy branch to load this group into",
                      "type": "string"
                    },
                    "owner_role": {
                      "description": "The Conjur Role that will own this group",
                      "type": "string"
                    },
                    "owner_type": {
                      "description": "The resource type of the owner of this group",
                      "type": "string"
                    },
                    "annotations": {
                      "description": "Additional annotations",
                      "type": "object"
                    }
                  },
                  "required": %w[id branch]
                }
              }.to_json)
            end
          end
        end
      end
    end
  end
end
