# frozen_string_literal: true

module Factories
  module Templates
    module Base
      module V1
        class BasePolicy
          class << self
            def policy
              <<~TEMPLATE
                - !policy
                  id: conjur
                  body:
                  - !policy
                    id: factories
                    body:
                    - !policy
                      id: core
                      annotations:
                        description: "Create Conjur primatives and manage permissions"
                      body:
                      - !variable
                        id: v1/user
                        annotations:
                          description: Create a new User

                      - !variable v1/grant
                      - !variable v1/group
                      - !variable v1/host
                      - !variable v1/layer
                      - !variable v1/managed-policy
                      - !variable v1/policy
                      - !variable v1/user

                    - !policy
                      id: authenticators
                      annotations:
                        description: "Generate new Authenticators"
                      body:
                      - !variable v1/authn-oidc
                    - !policy
                      id: connections
                      annotations:
                        description: "Create connections to external services"
                      body:
                      - !variable v1/database
                      - !variable v2/database
              TEMPLATE
            end
          end
        end
      end
    end
  end
end
