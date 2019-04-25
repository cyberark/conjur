Feature: Users can authneticate with OIDC authenticator

  Background:
    Given a policy:
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

  Scenario: A valid id token to get Conjur access token
    # We want to verify the returned access token is valid for retrieving a secret
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I get authorization code for username "alice" and password "alice"
    And I fetch an ID Token
    When I authenticate via OIDC with id token
    Then user "alice" is authorized
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user

  Scenario: A valid id token with email as id-token-user-property
    Given I extend the policy with:
    """
    - !user alice@conjur.net

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice@conjur.net
    """
    When I add the secret value "email" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property"
    And I get authorization code for username "alice" and password "alice"
    And I fetch an ID Token
    And I authenticate via OIDC with id token
    Then user "alice@conjur.net" is authorized

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
    And I get authorization code for username "bob" and password "bob"
    And I fetch an ID Token
    When I authenticate via OIDC with id token
    Then user "bob" is authorized

  Scenario: Non-existing username in ID token is denied
    Given I get authorization code for username "not_in_conjur" and password "not_in_conjur"
    And I fetch an ID Token
    And I save the log data from bookmark "bookmark_not_in_conjur"
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The log filtered from bookmark "bookmark_not_in_conjur" contains "1" messages:
    """
    Authentication Error: #<Authentication::NotDefinedInConjur: User 'not_in_conjur' is not defined in Conjur
    """

  Scenario: User that is not permitted to webservice in ID token is denied
    Given I extend the policy with:
    """
    - !user bob
    """
    And I get authorization code for username "bob" and password "bob"
    And I fetch an ID Token
    And I save the log data from bookmark "bookmark_bob"
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The log filtered from bookmark "bookmark_bob" contains "1" messages:
    """
    [OIDC] User 'bob' is not authorized to authenticate with webservice 'cucumber:webservice:conjur/authn-oidc/keycloak'
    """

  Scenario: ID token without value of variable id-token-user-property is denied
    When I add the secret value "non_existing_field" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property"
    And I get authorization code for username "alice" and password "alice"
    And I fetch an ID Token
    And I save the log data from bookmark "bookmark_alice"
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The log filtered from bookmark "bookmark_alice" contains "1" messages:
    """
    Authentication Error: #<Authentication::AuthnOidc::IdTokenFieldNotFoundOrEmpty: Field 'non_existing_field' not found or empty in ID Token
    """

  Scenario: Missing id token is a bad request
    Given I save the log data from bookmark "bookmark_bad_req"
    When I authenticate via OIDC with no id token
    Then it is a bad request
    And The log filtered from bookmark "bookmark_bad_req" contains "1" messages:
    """
    Authentication Error: #<Authentication::MissingRequestParam: field 'id_token' is missing or empty in request body
    """

  Scenario: Empty id token is a bad request
    Given I save the log data from bookmark "bookmark_empty_token"
    When I authenticate via OIDC with empty id token
    Then it is a bad request
    And The log filtered from bookmark "bookmark_empty_token" contains "1" messages:
    """
    Authentication Error: #<Authentication::MissingRequestParam: field 'id_token' is missing or empty in request body
    """

    # Should be crashed in GA, update the message to "account does not exists"
  Scenario: non-existing account in request is denied
    Given I get authorization code for username "alice" and password "alice"
    And I fetch an ID Token
    And I save the log data from bookmark "bookmark_not_existing_acnt"
    When I authenticate via OIDC with id token and account "non-existing"
    Then it is unauthorized
    And The log filtered from bookmark "bookmark_not_existing_acnt" contains "1" messages:
    """
    Authentication Error: #<Conjur::RequiredResourceMissing: Missing required resource: non-existing:variable:conjur/authn-oidc/keycloak/provider-uri
    """

  Scenario: admin user is denied
    Given I get authorization code for username "admin" and password "admin"
    And I fetch an ID Token
    And I save the log data from bookmark "bookmark_admin_blocked"
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The log filtered from bookmark "bookmark_admin_blocked" contains "1" messages:
    """
    Authentication Error: #<Authentication::AuthnOidc::AdminAuthenticationDenied: admin user is not allowed to authenticate with OIDC
    """
