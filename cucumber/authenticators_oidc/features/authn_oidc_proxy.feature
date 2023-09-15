@authenticators_oidc
Feature: OIDC Authenticator V2 - Users can authenticate with OIDC authenticator through a proxy

  In this feature we define an OIDC authenticator in policy and perform authentication
  with Conjur. Conjur will be accessing the OIDC provider through a proxy determined by
  the environment variables: http_proxy, https_proxy, HTTP_PROXY, HTTPS_PROXY.

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
  Scenario: A valid code to get Conjur access token from webservice with http_proxy set
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a code for username "alice" and password "alice" from "keycloak2"
    And I set environment variable "http_proxy" to "http://tinyproxy:8888"
    And I authenticate via OIDC V2 with code and service-id "keycloak2"
    Then user "alice" has been authorized by Conjur for 60 minutes
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user

  @smoke
  Scenario: A valid code to get Conjur access token from webservice with HTTP_PROXY set
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a code for username "alice" and password "alice" from "keycloak2"
    And I set environment variable "HTTP_PROXY" to "http://tinyproxy:8888"
    And I authenticate via OIDC V2 with code and service-id "keycloak2"
    Then user "alice" has been authorized by Conjur for 60 minutes
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user

  @smoke
  Scenario: A valid code to get Conjur access token from webservice with https_proxy set
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a code for username "alice" and password "alice" from "keycloak2"
    And I set environment variable "https_proxy" to "http://tinyproxy:8888"
    And I authenticate via OIDC V2 with code and service-id "keycloak2"
    Then user "alice" has been authorized by Conjur for 60 minutes
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user

  @smoke
  Scenario: A valid code to get Conjur access token from webservice with HTTP_PROXY set
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a code for username "alice" and password "alice" from "keycloak2"
    And I set environment variable "HTTPS_PROXY" to "http://tinyproxy:8888"
    And I authenticate via OIDC V2 with code and service-id "keycloak2"
    Then user "alice" has been authorized by Conjur for 60 minutes
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user

  @negative @acceptance
  Scenario: Unauthenticated is raised in case of an invalid HTTPS_PROXY setting
    Given I set environment variable "HTTPS_PROXY" to "https://fakeproxy"
    And I save my place in the log file
    When I fetch a code for username "alice" and password "alice" from "keycloak2"
    # Then it is a bad request
    Then The following appears in the log after my savepoint:
    """
    Errors::Authentication::OAuth::ProviderDiscoveryFailed
    """

  @negative @acceptance
  Scenario: Unauthenticated is raised in case of an invalid https_proxy setting
    Given I set environment variable "https_proxy" to "https://fakeproxy"
    And I save my place in the log file
    When I fetch a code for username "alice" and password "alice" from "keycloak2"
    # Then it is a bad request
    Then The following appears in the log after my savepoint:
    """
    Errors::Authentication::OAuth::ProviderDiscoveryFailed
    """

  # @negative @acceptance
  # Scenario: Unauthenticated is raised in case of an invalid HTTP_PROXY setting
  #   Given I set environment variable "HTTP_PROXY" to "https://fakeproxy"
  #   And I save my place in the log file
  #   When I fetch a code for username "alice" and password "alice" from "keycloak2"
  #   Then it is a bad request
  #   And The following appears in the log after my savepoint:
  #   """
  #   Errors::Authentication::OAuth::ProviderDiscoveryFailed
  #   """

  # @negative @acceptance
  # Scenario: Unauthenticated is raised in case of an invalid http_proxy setting
  #   Given I set environment variable "http_proxy" to "https://fakeproxy"
  #   And I save my place in the log file
  #   When I fetch a code for username "alice" and password "alice" from "keycloak2"
  #   Then it is a bad request
  #   And The following appears in the log after my savepoint:
  #   """
  #   Errors::Authentication::OAuth::ProviderDiscoveryFailed
  #   """
