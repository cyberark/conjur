# frozen_string_literal: true

require 'base64'

module Factories
  module Templates
    module Connections
      module V1
        class Database
          class << self
            def policy_template
              <<~TEMPLATE
                - !policy
                  id: <%= id %>
                  annotations:
                    factory: connections/v1/database
                  <% annotations.each do |key, value| -%>
                    <%= key %>: <%= value %>
                  <% end -%>

                  body:
                  - &variables
                    - !variable url
                    - !variable port
                    - !variable username
                    - !variable password
                    - !variable ssl-certificate
                    - !variable ssl-key
                    - !variable ssl-ca-certificate

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
                version: 1,
                policy: Base64.encode64(policy_template),
                policy_branch: "<%= branch %>",
                schema: {
                  "$schema": "http://json-schema.org/draft-06/schema#",
                  "title": "Database Connection Template",
                  "description": "All information for connecting to a database",
                  "type": "object",
                  "properties": {
                    "id": {
                      "description": "Database Connection Identifier",
                      "type": "string"
                    },
                    "branch": {
                      "description": "Policy branch to load this connection into",
                      "type": "string"
                    },
                    "annotations": {
                      "description": "Additional annotations",
                      "type": "object"
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
                          "type": "string"
                        },
                        "username": {
                          "description": "Database Username",
                          "type": "string"
                        },
                        "password": {
                          "description": "Database Password",
                          "type": "string"
                        },
                        "ssl-certificate": {
                          "description": "Client SSL Certificate",
                          "type": "string"
                        },
                        "ssl-key": {
                          "description": "Client SSL Key",
                          "type": "string"
                        },
                        "ssl-ca-certificate": {
                          "description": "CA Root Certificate",
                          "type": "string"
                        }
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
end
