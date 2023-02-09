# frozen_string_literal: true

require 'base64'

module Factory
  module Templates
    module Core
      class User
        class << self
          def policy_template
            <<~TEMPLATE
              - !user
                id: <%= id %>
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
              target_policy_namespace: "<%= branch %>",
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
