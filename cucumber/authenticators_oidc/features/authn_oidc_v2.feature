@authenticators_oidc @skip
Feature: OIDC Authenticator V2 - Users can authenticate with OIDC authenticator

  In this feature we define an OIDC authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the user to
  execute it, to verify not only that the user can authenticate with the OIDC
  Authenticator, but that it can retrieve a secret using the Conjur access token.

  Background:
    Given the following environment variables are available:
      | context_variable           | environment_variable   | default_value                                                   |
      | oidc_provider_internal_uri | PROVIDER_INTERNAL_URI  | http://keycloak:8080/auth/realms/master/protocol/openid-connect |
      | oidc_scope                 | KEYCLOAK_SCOPE         | openid                                                          |
      | oidc_client_id             | KEYCLOAK_CLIENT_ID     | conjurClient                                                    |
      | oidc_client_secret         | KEYCLOAK_CLIENT_SECRET | 1234                                                            |
      | oidc_provider_uri          | PROVIDER_URI           | https://keycloak:8443/auth/realms/master                        |
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

      - !policy
        id: conjur/authn-oidc/keycloak2-long-lived
        body:
          - !webservice
            annotations:
              description: Authentication service for Keycloak, based on Open ID Connect. Uses a 2 hour token TTL.
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
      - !grant
        role: !group conjur/authn-oidc/keycloak2-long-lived/users
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
      | conjur/authn-oidc/keycloak2/ca-cert                   | oidc_ca_cert        |               |
      | conjur/authn-oidc/keycloak2-long-lived/provider-uri   | oidc_provider_uri   |               |
      | conjur/authn-oidc/keycloak2-long-lived/client-id      | oidc_client_id      |               |
      | conjur/authn-oidc/keycloak2-long-lived/client-secret  | oidc_client_secret  |               |
      | conjur/authn-oidc/keycloak2-long-lived/claim-mapping  | oidc_claim_mapping  |               |
      | conjur/authn-oidc/keycloak2-long-lived/redirect-uri   | oidc_redirect_url   |               |
      | conjur/authn-oidc/keycloak2-long-lived/response-type  |                     | code          |
      | conjur/authn-oidc/keycloak2-long-lived/token-ttl      |                     | PT2H          |
      | conjur/authn-oidc/keycloak2-long-lived/ca-cert        | oidc_ca_cert        |               |

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

  @smoke
  Scenario: A valid code to get Conjur access token from webservice with custom token TTL
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a code for username "alice" and password "alice" from "keycloak2-long-lived"
    And I save my place in the audit log file
    And I authenticate via OIDC V2 with code and service-id "keycloak2-long-lived"
    Then user "alice" has been authorized by Conjur for 2 hours
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak2-long-lived
    """

  @smoke
  Scenario: A valid code with email as claim mapping
    Given I extend the policy with:
    """
    - !user alice@conjur.net
    - !grant
      role: !group conjur/authn-oidc/keycloak2/users
      member: !user alice@conjur.net
    """
    When I add the secret value "email" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/claim-mapping"
    And I fetch a code for username "alice@conjur.net" and password "alice" from "keycloak2"
    And I authenticate via OIDC V2 with code
    Then user "alice@conjur.net" has been authorized by Conjur

  @smoke
  Scenario: Adding a group to keycloak2/users group permits users to authenticate
    Given I extend the policy with:
    """
    - !user
      id: bob.somebody
    - !group more-users
    - !grant
      role: !group more-users
      member: !user bob.somebody
    - !grant
      role: !group conjur/authn-oidc/keycloak2/users
      member: !group more-users
    """
    And I fetch a code for username "bob@conjur.net" and password "bob" from "keycloak2"
    When I authenticate via OIDC V2 with code
    Then user "bob.somebody" has been authorized by Conjur

  @negative @acceptance
  Scenario: Non-existing username in claim mapping is denied
    Given I fetch a code for username "not_in_conjur" and password "not_in_conjur" from "keycloak2"
    And I save my place in the log file
    When I authenticate via OIDC V2 with code
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """

  @negative @acceptance
  Scenario: User that is not permitted to webservice in claim mapping is denied
    Given I extend the policy with:
    """
    - !user
      id: bob@conjur.net
    """
    And I fetch a code for username "bob@conjur.net" and password "bob" from "keycloak2"
    And I save my place in the log file
    When I authenticate via OIDC V2 with code
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """

  @negative @acceptance
  Scenario: Code without value of variable claim mapping is denied
    When I add the secret value "non_existing_field" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/claim-mapping"
    And I fetch a code for username "alice@conjur.net" and password "alice" from "keycloak2"
    And I save my place in the log file
    When I authenticate via OIDC V2 with code
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty: CONJ00013E Claim 'non_existing_field' not found or empty in ID token. This claim is defined in the claim-mapping variable.
    """

  @negative @acceptance
  Scenario: Adding a group to keycloak2/users group permits users to authenticate
    Given I extend the policy with:
    """
    - !user
      id: bob
      annotations:
        authn-oidc/identity: bob.somebody
    - !group more-users
    - !grant
      role: !group more-users
      member: !user bob
    - !grant
      role: !group conjur/authn-oidc/keycloak2/users
      member: !group more-users
    """

  @negative @acceptance
  Scenario: Missing code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice" from "keycloak2"
    When I authenticate via OIDC V2 with no code in the request
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """

  @negative @acceptance
  Scenario: Empty code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice" from "keycloak2"
    When I authenticate via OIDC V2 with code ""
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """

  @negative @acceptance
  Scenario: Invalid code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice" from "keycloak2"
    When I authenticate via OIDC V2 with code "bad-code"
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnOidc::TokenRetrievalFailed
    """

  @negative @acceptance
  Scenario: Bad OIDC provider credentials
    Given I save my place in the log file
    And I fetch a code for username "alice" and password "notalice" from "keycloak2"
    When I authenticate via OIDC V2 with code
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """

  @negative @acceptance
  Scenario: Non-Existent authenticator is not found
    Given I save my place in the log file
    And I fetch a code for username "alice" and password "alice" from "keycloak2"
    When I authenticate via OIDC V2 with code and service-id "non-exist"
    Then it is not found
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequestedResourceNotFound: CONJ00123E Resource
    """

  @smoke
  Scenario: provider-uri dynamic change
    And I fetch a code for username "alice" and password "alice" from "keycloak2"
    And I authenticate via OIDC V2 with code
    And user "alice" has been authorized by Conjur
    # Update provider uri to a different hostname and verify `provider-uri` has changed
    When I add the secret value "https://different-provider:8443" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/provider-uri"
    And I authenticate via OIDC V2 with code
    Then it is unauthorized
    # Check recovery to a valid provider uri
    And I revert the value of the resource "cucumber:variable:conjur/authn-oidc/keycloak2/provider-uri"
    And I fetch a code for username "alice" and password "alice" from "keycloak2"
    And I authenticate via OIDC V2 with code
    Then user "alice" has been authorized by Conjur

  @negative @acceptance
  Scenario: Unauthenticated is raised in case of an invalid OIDC Provider hostname
    Given I fetch a code for username "alice" and password "alice" from "keycloak2"
    And I authenticate via OIDC V2 with code
    And user "alice" has been authorized by Conjur
    # Update provider uri to reachable but invalid hostname
    When I add the secret value "http://127.0.0.1.com/" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/provider-uri"
    And I save my place in the log file
    And I authenticate via OIDC V2 with code
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::OAuth::ProviderDiscoveryFailed
    """
