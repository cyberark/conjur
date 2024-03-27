@ipv6
Feature: OIDC Authenticator V2 IPv6 - Users can authenticate with OIDC authenticator

  In this feature we define an OIDC authenticator in policy and perform authentication
  with Conjur. We want to confirm that an IPv6 address can be used as the OIDC provider URI
  without issue, so we only test the happy path.

  Background:
    Given the following environment variables are available:
      | context_variable           | environment_variable   | default_value                                                   |
      | oidc_provider_internal_uri | PROVIDER_INTERNAL_URI  | http://keycloak_ipv6:8080/auth/realms/master/protocol/openid-connect |
      | oidc_scope                 | KEYCLOAK_SCOPE         | openid                                                          |
      | oidc_client_id             | KEYCLOAK_CLIENT_ID     | conjurClient                                                    |
      | oidc_client_secret         | KEYCLOAK_CLIENT_SECRET | 1234                                                            |
      | oidc_provider_uri          | PROVIDER_URI           | https://keycloak_ipv6:8443/auth/realms/master                        |
      | oidc_claim_mapping         | ID_TOKEN_USER_PROPERTY | preferred_username                                              |
      | oidc_redirect_url          | KEYCLOAK_REDIRECT_URI  | http://conjur:3000/authn-oidc/keycloak2/cucumber/authenticate   |
      | oidc_ca_cert               | KEYCLOAK_CA_CERT       |                                                                 |

    And I load a policy:
    """
      - !policy
        id: conjur/authn-oidc/keycloak2
        body:
          - !webservice
            annotations:
              description: Authentication service for Keycloak, based on Open ID Connect. Uses the default token TTL of 8 minutes.
          - !variable name
          - !variable provider-uri
          - !variable response-type
          - !variable client-id
          - !variable client-secret
          - !variable claim-mapping
          - !variable state
          - !variable nonce
          - !variable redirect-uri
          - !variable provider-scope
          - !variable token-ttl
          - !variable ca-cert
          - !group users
          - !permit
            role: !group users
            privilege: [ read, authenticate ]
            resource: !webservice

      - !user
        id: alice
      - !grant
        role: !group conjur/authn-oidc/keycloak2/users
        member: !user alice
    """

    And I set the following conjur variables:
      | variable_id                                           | context_variable    | default_value |
      | conjur/authn-oidc/keycloak2/provider-uri              | oidc_provider_uri   |               |
      | conjur/authn-oidc/keycloak2/client-id                 | oidc_client_id      |               |
      | conjur/authn-oidc/keycloak2/client-secret             | oidc_client_secret  |               |
      | conjur/authn-oidc/keycloak2/claim-mapping             | oidc_claim_mapping  |               |
      | conjur/authn-oidc/keycloak2/redirect-uri              | oidc_redirect_url   |               |
      | conjur/authn-oidc/keycloak2/response-type             |                     | code          |

  @smoke
  Scenario: A valid code to get Conjur access token from webservice with default token TTL
    # We want to verify the returned access token is valid for retrieving a secret
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a code for username "alice" and password "alice" from "keycloak2"
    And I save my place in the audit log file
    And I authenticate via OIDC V2 with code and service-id "keycloak2"
    Then user "alice" has been authorized by Conjur for 60 minutes
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak2
    """
