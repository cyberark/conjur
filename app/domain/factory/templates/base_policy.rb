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
                      - !variable host
                      - !variable group
                      - !variable policy
                      - !variable layer
                      - !variable grant
                      - !variable permit
                      - !variable managed-policy
                  - !policy
                    id: authenticators
                    body:
                      - !variable authn-azure
                      - !variable authn-iam
                      - !variable authn-oidc
                      - !variable authn-ldap
                      - !variable authn-k8s
                      - !variable authn-gcp
                      - !variable authn-jwt
          TEMPLATE
        end
      end
    end
  end
end
