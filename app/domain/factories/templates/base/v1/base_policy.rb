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
                      body:
                      - !variable
                        id: v1/user
                        annotations:
                          description: Create a new User

                      - !variable v1/group
                      - !variable v1/policy
                      - !variable v1/grant
                      - !variable v1/managed-policy

                    - !policy
                      id: authenticators
                      body:
                      - !variable v1/authn-oidc
                    - !policy
                      id: connections
                      body:
                      - !variable v1/database
              TEMPLATE
            end
          end
        end
      end
    end
  end
end
