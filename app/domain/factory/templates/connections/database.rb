# frozen_string_literal: true

require 'base64'

module Factory
  module Templates
    module Connections
      class Database
        class << self
          def policy_template
            <<~TEMPLATE
              - !policy
                id: <%= id %>
                annotations:
                  factory: connections/database
                body:
                - &variables
                  - !variable url
                  - !variable port
                  - !variable username
                  - !variable password

                - !group consumers
                - !group administrators

                # consumers can read and execute
                - !permit
                  resource: *variables
                  privileges: [ read, execute ]
                  role: !group consumers

                # administrators can update (and read and execute, via role grant)
                - !permit
                  resource: *variables
                  privileges: [ update ]
                  role: !group administrators

                # administrators has role consumers
                - !grant
                  member: !group administrators
                  role: !group consumers
            TEMPLATE
          end

          def data
            Base64.encode64({
              policy: Base64.encode64(policy_template),
              target_policy_namespace: "<%= branch %>",
              target_variable_namespace: "<%= branch %>/<%= id %>",
              schema: {
                "$schema": "http://json-schema.org/draft-06/schema#",
                "title": "Database Connection Template",
                "description": "All information for connecting to a database",
                "type": "object",
                "properties": {
                  "id": {
                    "description": "Database Connection ID",
                    "type": "string"
                  },
                  "branch": {
                    "description": "Policy branch to load this database connection into",
                    "type": "string"
                  },
                  "variables": {
                    "type": "object",
                    "properties": {
                      "url": {
                        "description": "Database URL",
                        "type": "string"
                      },
                      "port": {
                        "description": "Database Port",
                        "type": "integer"
                      },
                      "username": {
                        "description": "Database Username",
                        "type": "string"
                      },
                      "password": {
                        "description": "Database Password",
                        "type": "string"
                      },
                    },
                    "required": %w[url port username password]
                  }
                },
                "required": %w[id branch variables]
              }
            }.to_json)
          end
        end
      end
    end
  end
end
