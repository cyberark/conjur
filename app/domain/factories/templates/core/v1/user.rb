# frozen_string_literal: true

require 'base64'

module Factories
  module Templates
    module Core
      module V1
        class User
          class << self
            def policy_template
              <<~TEMPLATE
                - !user
                  id: <%= id %>
                <% if defined?(owner_role) && defined?(owner_type) -%>
                  owner: !<%= owner_type %> <%= owner_role %>
                <% end -%>
                <% if defined?(ip_range) -%>
                  restricted_to: <%= ip_range %>
                <% end -%>
                <% if defined?(annotations) -%>
                  annotations:
                <% annotations.each do |key, value| -%>
                    <%= key %>: <%= value %>
                <% end -%>
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
                  "title": "User Template",
                  "description": "Creates a Conjur User",
                  "type": "object",
                  "properties": {
                    "id": {
                      "description": "User ID",
                      "type": "string"
                    },
                    "branch": {
                      "description": "Policy branch to load this user into",
                      "type": "string"
                    },
                    "owner_role": {
                      "description": "The Conjur Role that will own this user",
                      "type": "string"
                    },
                    "owner_type": {
                      "description": "The resource type of the owner of this user",
                      "type": "string"
                    },
                    "ip_range": {
                      "description": "Limits the network range the user is allowed to authenticate from",
                      "type": "string"
                    },
                    "annotations": {
                      "description": "Additional annotations to add to the user",
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
