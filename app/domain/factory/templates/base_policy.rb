# frozen_string_literal: true

module Factory
  module Templates
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
                  - !variable user
                  - !variable group
                  - !variable policy
                  - !variable grant
                  - !variable managed-policy
                - !policy
                  id: authenticators
                  body:
                  - !variable authn-oidc
                - !policy
                  id: connections
                  body:
                  - !variable database
          TEMPLATE
        end
      end
    end
  end
end
