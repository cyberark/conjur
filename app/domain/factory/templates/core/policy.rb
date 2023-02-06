# frozen_string_literal: true

require 'base64'

module Factory
  module Templates
    module Core
      class Policy
        class << self
          def policy_template
            <<~TEMPLATE
              - !policy
                id: <%= id %>
                <% if defined?(owner) %>
                owner: <%= owner %>
                <% end %>
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
                  "owner": {
                    "description": "Optional owner of this policy",
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
