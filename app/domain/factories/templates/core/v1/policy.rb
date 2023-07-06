# frozen_string_literal: true

require 'base64'

module Factories
  module Templates
    module Core
      module V1
        class Policy
          class << self
            def policy_template
              <<~TEMPLATE
                - !policy
                  id: <%= id %>
                <% if defined?(owner_role) && defined?(owner_type) -%>
                  owner: !<%= owner_type %> <%= owner_role %>
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
                  "description": "Creates a Conjur Policy",
                  "type": "object",
                  "properties": {
                    "id": {
                      "description": "Policy ID",
                      "type": "string"
                    },
                    "branch": {
                      "description": "Policy branch to load this policy into",
                      "type": "string"
                    },
                    "owner_role": {
                      "description": "The Conjur Role that will own this policy",
                      "type": "string"
                    },
                    "owner_type": {
                      "description": "The resource type of the owner of this policy",
                      "type": "string"
                    },
                    "annotations": {
                      "description": "Additional annotations to add to the policy",
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
