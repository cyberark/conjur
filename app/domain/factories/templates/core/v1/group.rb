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
                version: 1,
                policy: Base64.encode64(policy_template),
                policy_namespace: "<%= branch %>",
                schema: {
                  "$schema": "http://json-schema.org/draft-06/schema#",
                  "title": "Group Template",
                  "description": "Creates a Conjur Group",
                  "type": "object",
                  "properties": {
                    "id": {
                      "description": "Group ID",
                      "type": "string"
                    },
                    "branch": {
                      "description": "Policy branch to load this group into",
                      "type": "string"
                    },
                    "annotations": {
                      "description": "Additional annotations to add to the group",
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
