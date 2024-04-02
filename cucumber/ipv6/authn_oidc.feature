@ipv6
Feature: OIDC Authenticator IPv6 - Hosts can authenticate with OIDC authenticator

  In this feature we define an OIDC authenticator in policy and perform authentication
  with Conjur. We want a happy path to ensure that the OIDC authenticator is working
  when a provider is listening is only reachable on an IPv6 address.

  Background:
    Given the following environment variables are available:
      | context_variable            | environment_variable   | default_value                                                    |
      | oidc_provider_internal_uri  | PROVIDER_INTERNAL_URI  | https://keycloak_ipv6:8443/auth/realms/master/protocol/openid-connect |
      | oidc_scope                  | KEYCLOAK_SCOPE         | openid                                                           |
      | oidc_client_id              | KEYCLOAK_CLIENT_ID     | conjurClient                                                     |
      | oidc_client_secret          | KEYCLOAK_CLIENT_SECRET | 1234                                                             |
      | oidc_provider_uri           | PROVIDER_URI           | https://keycloak_ipv6:8443/auth/realms/master                         |
      | oidc_id_token_user_property | ID_TOKEN_USER_PROPERTY | preferred_username                                               |
      | oidc_ca_cert                | KEYCLOAK_CA_CERT       |                                                                  |

    And I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !variable
        id: ca-cert

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I set the following conjur variables:
      | variable_id                                       | context_variable            |
      | conjur/authn-oidc/keycloak/id-token-user-property | oidc_id_token_user_property |
      | conjur/authn-oidc/keycloak/provider-uri           | oidc_provider_uri           |

  @smoke
  Scenario: A valid id token in header to get Conjur access token
    # We want to verify the returned access token is valid for retrieving a secret
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the audit log file
    When I authenticate via OIDC with id token in header
    Then user "alice" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak
    """

  @smoke
  Scenario: A valid id token in body to get Conjur access token
    # We want to verify the returned access token is valid for retrieving a secret
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the audit log file
    When I authenticate via OIDC with id token
    Then user "alice" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak
    """
