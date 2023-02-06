# frozen_string_literal: true

require 'base64'

module Factory
  module Templates
    module Core
      class ManagedPolicy
        class << self
          def policy_template
            <<~TEMPLATE
              - !group <%= name %>-admins
              - !policy
                id: <%= name %>
                owner: !group <%= name %>-admins
                <% if defined?(annotations) %>
                annotations:
                <% annotations.each do |key, value| -%>
                  <%= key %>: <%= value %>
                <% end -%>
                <% end -%>
            TEMPLATE
          end

          def data
            Base64.encode64({
              policy: Base64.encode64(policy_template),
              schema: {
                "$schema": "https://json-schema.org/draft/2020-12/schema",
                "$id": "https://example.com/product.schema.json",
                "title": "Managed Policy Template",
                "description": "Policy with an owner group",
                "type": "object",
                "properties": {
                  "name": {
                    "description": "Policy name (used to create the policy ID and the <name>-admins owner group)",
                    "type": "string"
                  },
                  "branch": {
                    "description": "Policy branch to load this policy into",
                    "type": "string"
                  },
                  "annotations": {
                    "description": "Additional annotations to add to the user",
                    "type": "object"
                  }
                },
                "required": %w[name branch]
              }
            }.to_json)
          end
        end
      end
    end
  end
end
