@authenticators_oidc
Feature: OIDC Authenticator V2 - Users can authenticate with OIDC authenticator

  In this feature we define an OIDC authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the user to
  execute it, to verify not only that the user can authenticate with the OIDC
  Authenticator, but that it can retrieve a secret using the Conjur access token.

  Background:
    Given I load a policy:
    """
      - !policy
        id: conjur/authn-oidc/keycloak2
        body:
          - !webservice
            annotations:
              description: Authentication service for Keycloak, based on Open ID Connect.
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
    And I am the super-user
    And I successfully set OIDC V2 variables for "keycloak2"

  @smoke
  Scenario: A valid code to get Conjur access token
    # We want to verify the returned access token is valid for retrieving a secret
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a code for username "alice" and password "alice"
    And I save my place in the audit log file
    When I authenticate via OIDC V2 with code
    Then user "alice" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak2
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
    And I fetch a code for username "alice@conjur.net" and password "alice"
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
    And I fetch a code for username "bob@conjur.net" and password "bob"
    When I authenticate via OIDC V2 with code
    Then user "bob.somebody" has been authorized by Conjur

  @negative @acceptance
  Scenario: Non-existing username in claim mapping is denied
    Given I fetch a code for username "not_in_conjur" and password "not_in_conjur"
    And I save my place in the log file
    When I authenticate via OIDC V2 with code
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """
#    And The following appears in the audit log after my savepoint:
#    """
#     failed to authenticate with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak2
#    """

  @negative @acceptance
  Scenario: User that is not permitted to webservice in claim mapping is denied
    Given I extend the policy with:
    """
    - !user
      id: bob@conjur.net
    """
    And I fetch a code for username "bob@conjur.net" and password "bob"
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
    And I fetch a code for username "alice@conjur.net" and password "alice"
    And I save my place in the log file
    When I authenticate via OIDC V2 with code
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
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

#  @negative @acceptance
#  Scenario: Adding a group to keycloak2/users group permits users to authenticate
#    Given I extend the policy with:
#    """
#    - !user
#      id: bob.somebody
#      annotations:
#        authn-oidc/identity: bob.somebody
#    - !group more-users
#    - !grant
#      role: !group more-users
#      member: !user bob.somebody
#    - !grant
#      role: !group conjur/authn-oidc/keycloak2/users
#      member: !group more-users
#    """
#
#    Given I extend the policy with:
#    """
#    - !user
#      id: chad
#      annotations:
#        authn-oidc/identity: bob.somebody
#    - !group more-users
#    - !grant
#      role: !group more-users
#      member: !user chad
#    - !grant
#      role: !group conjur/authn-oidc/keycloak2/users
#      member: !group more-users
#    """
#    Given I save my place in the log file
#    And I fetch a code for username "bob.somebody" and password "bob"
#    When I authenticate via OIDC V2 with code
#    Then it is forbidden
#    And The following appears in the log after my savepoint:
#    """
#    CONJ00009E 'bob.somebody' matched multiple roles
#    """

  @negative @acceptance
  Scenario: Missing code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice"
    When I authenticate via OIDC V2 with no code in the request
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """
#    And The following appears in the audit log after my savepoint:
#    """
#    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
#    """

  @negative @acceptance
  Scenario: Empty code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice"
    When I authenticate via OIDC V2 with code ""
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """
#    And The following appears in the audit log after my savepoint:
#    """
#    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
#    """

  @negative @acceptance
  Scenario: Invalid code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice"
    When I authenticate via OIDC V2 with code "bad-code"
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Rack::OAuth2::Client::Error
    """

  @negative @acceptance
  Scenario: Invalid state is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice" and password "alice"
    When I authenticate via OIDC V2 with state "bad-state"
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnOidc::StateMismatch
    """

  @negative @acceptance
  Scenario: Bad OIDC provider credentials
    Given I save my place in the log file
    And I fetch a code for username "alice" and password "notalice"
    When I authenticate via OIDC V2 with code
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """

  @negative @acceptance
  Scenario: Non-Existent authenticator is not found
    Given I save my place in the log file
    And I fetch a code for username "alice" and password "alice"
    When I authenticate via OIDC V2 with code and service-id "non-exist"
    Then it is not found
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequestedResourceNotFound: CONJ00123E Resource
    """

#  @negative @acceptance
#  Scenario: non-existing account in request is denied
#    Given I save my place in the log file
#    When I authenticate via OIDC V2 with code and account "non-existing"
#    Then it is unauthorized
#    And The following appears in the log after my savepoint:
#    """
#    Errors::Authentication::Security::AccountNotDefined
#    """
#    And The following appears in the audit log after my savepoint:
#    """
#    non-existing:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
#    """

#  @negative @acceptance
#  Scenario: admin user is denied
#    And I fetch a code for username "admin" and password "admin"
#    And I save my place in the log file
#    When I authenticate via OIDC V2 with code
#    Then it is unauthorized
#    And The following appears in the log after my savepoint:
#    """
#    Errors::Authentication::AdminAuthenticationDenied
#    """
#    And The following appears in the audit log after my savepoint:
#    """
#    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
#    """

  @smoke
  Scenario: provider-uri dynamic change
    And I fetch a code for username "alice" and password "alice"
    And I authenticate via OIDC V2 with code
    And user "alice" has been authorized by Conjur
    # Update provider uri to a different hostname and verify `provider-uri` has changed
    When I add the secret value "https://different-provider:8443" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/provider-uri"
    And I authenticate via OIDC V2 with code
    Then it is unauthorized
    # Check recovery to a valid provider uri
    When I successfully set OIDC V2 variables for "keycloak2"
    And I fetch a code for username "alice" and password "alice"
    And I authenticate via OIDC V2 with code
    Then user "alice" has been authorized by Conjur

  @negative @acceptance
  Scenario: Unauthenticated is raised in case of an invalid OIDC Provider hostname
    Given I fetch a code for username "alice" and password "alice"
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

  # This test runs a failing authentication request that is already
  # tested in another scenario (User that is not permitted to webservice in ID token is denied).
  # We run it again here to verify that we write a message to the audit log
#  @acceptance
#  Scenario: Authentication failure is written to the audit log
#    Given I extend the policy with:
#    """
#    - !user
#      id: bob
#      annotations:
#        authn-oidc/identity: bob.somebody@cyberark.com
#    """
#    And I fetch a code for username "bob.somebody@cyberark.com" and password "bob"
#    And I save my place in the audit log file
#    When I authenticate via OIDC V2 with code
#    Then it is forbidden
#    And The following appears in the audit log after my savepoint:
#    """
#    cucumber:user:bob failed to authenticate with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak
#    """
