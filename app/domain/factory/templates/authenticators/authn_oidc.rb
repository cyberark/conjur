# frozen_string_literal: true

require 'base64'

module Factory
  module Templates
    module Authenticators
      class AuthnOidc
        class << self
          def policy_template
            <<~TEMPLATE
              - !policy
                id: <%= id %>
                body:
                - !webservice

                - !variable provider-uri
                - !variable client-id
                - !variable client-secret
                - !variable redirect-uri
                - !variable claim-mapping

                - !group
                  id: authenticatable
                  annotations:
                    description: Group with permission to authenticate using this authenticator

                - !permit
                  role: !group authenticatable
                  privilege: [ read, authenticate ]
                  resource: !webservice

                - !webservice
                  id: status
                  annotations:
                    description: Web service for checking authenticator status

                - !group
                  id: operators
                  annotations:
                    description: Group with permission to check the authenticator status

                - !permit
                  role: !group operators
                  privilege: [ read ]
                  resource: !webservice status
            TEMPLATE
          end

          def data
            Base64.encode64({
              policy: Base64.encode64(policy_template),
              policy_namespace: "conjur/authn-oidc",
              schema: {
                "$schema": "http://json-schema.org/draft-06/schema#",
                "title": "Authn-OIDC Template",
                "description": "Create a new Authn-OIDC Authenticator",
                "type": "object",
                "properties": {
                  "id": {
                    "description": "Service ID of the Authenticator",
                    "type": "string"
                  },
                  "variables": {
                    "type": "object",
                    "properties": {
                      "provider-uri": {
                        "description": "OIDC Provider endpoint",
                        "type": "string"
                      },
                      "client-id": {
                        "description": "OIDC Client ID",
                        "type": "string"
                      },
                      "client-secret": {
                        "description": "OIDC Client Secret",
                        "type": "string"
                      },
                      "redirect-uri": {
                        "description": "Target URL to redirect to after successful authentication",
                        "type": "string"
                      },
                      "claim-mapping": {
                        "description": "OIDC JWT claim mapping. This value must match to a Conjur Host ID.",
                        "type": "string"
                      }
                    },
                    "required": %w[provider-uri client-id client-secret claim-mapping]
                  }
                },
                "required": %w[id variables]
              }
            }.to_json)
          end
        end
      end
    end
  end
end
