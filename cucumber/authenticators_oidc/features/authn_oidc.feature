@authenticators_oidc
Feature: OIDC Authenticator - Hosts can authenticate with OIDC authenticator

  In this feature we define an OIDC authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the host to
  execute it, to verify not only that the host can authenticate with the OIDC
  Authenticator, but that it can retrieve a secret using the Conjur access token.

  Background:
    Given I load a policy:
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
    And I am the super-user
    And I successfully set OIDC variables

  @smoke
  Scenario: A valid id token to get Conjur access token
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

  @smoke
  Scenario: A valid id token with email as id-token-user-property
    Given I extend the policy with:
    """
    - !user alice@conjur.net

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice@conjur.net
    """
    When I add the secret value "email" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property"
    And I fetch an ID Token for username "alice" and password "alice"
    And I authenticate via OIDC with id token
    Then user "alice@conjur.net" has been authorized by Conjur

  @smoke
  Scenario: Adding a group to keycloak/users group permits users to authenticate
    Given I extend the policy with:
    """
    - !user bob

    - !group more-users

    - !grant
      role: !group more-users
      member: !user bob

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !group more-users
    """
    And I fetch an ID Token for username "bob" and password "bob"
    When I authenticate via OIDC with id token
    Then user "bob" has been authorized by Conjur

  @negative @acceptance
  Scenario: Non-existing username in ID token is denied
    Given I fetch an ID Token for username "not_in_conjur" and password "not_in_conjur"
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:not_in_conjur failed to authenticate with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak
    """

  @negative @acceptance
  Scenario: User that is not permitted to webservice in ID token is denied
    Given I extend the policy with:
    """
    - !user bob
    """
    And I fetch an ID Token for username "bob" and password "bob"
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is forbidden
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource
    """

  @negative @acceptance
  Scenario: ID token without value of variable id-token-user-property is denied
    When I add the secret value "non_existing_field" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
    """

  @negative @acceptance
  Scenario: Missing id token is a bad request
    Given I save my place in the log file
    When I authenticate via OIDC with no id token
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
    """

  @negative @acceptance
  Scenario: Empty id token is a bad request
    Given I save my place in the log file
    When I authenticate via OIDC with empty id token
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
    """

  @negative @acceptance
  Scenario: non-existing account in request is denied
    Given I save my place in the log file
    When I authenticate via OIDC with id token and account "non-existing"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::AccountNotDefined
    """
    And The following appears in the audit log after my savepoint:
    """
    non-existing:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
    """

  @negative @acceptance
  Scenario: admin user is denied
    And I fetch an ID Token for username "admin" and password "admin"
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AdminAuthenticationDenied
    """
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
    """

  @smoke
  Scenario: provider-uri dynamic change
    And I fetch an ID Token for username "alice" and password "alice"
    And I authenticate via OIDC with id token
    And user "alice" has been authorized by Conjur
    # Update provider uri to a different hostname and verify `provider-uri` has changed
    When I add the secret value "https://different-provider:8443" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/provider-uri"
    And I authenticate via OIDC with id token
    Then it is unauthorized
    # Check recovery to a valid provider uri
    When I successfully set OIDC variables
    And I fetch an ID Token for username "alice" and password "alice"
    And I authenticate via OIDC with id token
    Then user "alice" has been authorized by Conjur

  @negative @acceptance
  Scenario: Unauthenticated is raised in case of an invalid OIDC Provider hostname
    Given I fetch an ID Token for username "alice" and password "alice"
    And I authenticate via OIDC with id token
    And user "alice" has been authorized by Conjur
    # Update provider uri to reachable but invalid hostname
    When I add the secret value "http://127.0.0.1.com/" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/provider-uri"
    And I save my place in the log file
    And I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::OAuth::ProviderDiscoveryFailed
    """

  # This test runs a failing authentication request that is already
  # tested in another scenario (User that is not permitted to webservice in ID token is denied).
  # We run it again here to verify that we write a message to the audit log
  @acceptance
  Scenario: Authentication failure is written to the audit log
    Given I extend the policy with:
    """
    - !user bob
    """
    And I fetch an ID Token for username "bob" and password "bob"
    And I save my place in the audit log file
    When I authenticate via OIDC with id token
    Then it is forbidden
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:bob failed to authenticate with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak
    """

  @negative @acceptance
  Scenario: Request with an existing user ID in URL is responded with not found
    Given I save my place in the log file
    When I authenticate via OIDC with no id token and user id "alice" in the request
    Then it is not found
    And The following appears in the log after my savepoint:
    """
    ActionController::RoutingError (No route matches [POST] "/authn-oidc/keycloak/cucumber/alice/authenticate")
    """

  @negative @acceptance
  Scenario: Request with a non-existing user ID in URL is responded with not found
    Given I save my place in the log file
    When I authenticate via OIDC with no id token and user id "non-exist" in the request
    Then it is not found
    And The following appears in the log after my savepoint:
    """
    ActionController::RoutingError (No route matches [POST] "/authn-oidc/keycloak/cucumber/non-exist/authenticate")
    """
