@authenticators_status
Feature: Authenticator status check

  Conjur supports a Status check where users can get immediate feedback
  on authenticator configuration.

  The Status check includes general checks (webservice is loaded, user is authorized
  to check the Authenticator status, etc.) and authenticator-specific checks (e.g in
  OIDC we check that the `provider-uri` variable is loaded and has a value).

  Scenarios in this file test only the general checks. Authenticator specific checks
  should go in a separate file (e.g authn_status_oidc.feature).

  We use the OIDC authenticator in these scenarios as an authenticator that
  implements the Status check but all these test are not OIDC-specific and do
  not require a running OIDC Provider in order to run.

  @negative @acceptance
  Scenario: An unauthorized user is responded with 403
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: managers
        annotations:
          description: Group of users who can check the status of the authn-oidc/keycloak authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I am the super-user
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 403
    And the authenticator status check fails with error "RoleNotAuthorizedOnResource: CONJ00006E"

  @negative @acceptance
  Scenario: An authenticator without an implemented status check returns 501
    Given I load a policy:
    """
    - !user alice
    """
    And I login as "alice"
    When I GET "/authn-ldap/test/cucumber/status"
    Then the HTTP response status code is 501
    And the authenticator status check fails with error "StatusNotSupported: CONJ00056E"

  @negative @acceptance
  Scenario: A non-existing authenticator status check returns 404
    Given I load a policy:
    """
    - !user alice
    """
    And I login as "alice"
    When I GET "/authn-nonexist/test/cucumber/status"
    Then the HTTP response status code is 404
    And the authenticator status check fails with error "AuthenticatorNotSupported: CONJ00001E"

  @negative @acceptance
  Scenario: A missing status webservice returns 500
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

      - !group
        id: managers
        annotations:
          description: Group of users who can check the status of the authn-oidc/keycloak authenticator

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "WebserviceNotFound: CONJ00005E"

  @negative @acceptance
  Scenario: A non-existing account name in the status request returns 500
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: managers
        annotations:
          description: Group of users who can check the status of the authn-oidc/keycloak authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/managers
      member: !user alice
    """
    And I am the super-user
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/non-existing-account/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "AccountNotDefined: CONJ00008E"

  @negative @acceptance
  Scenario: An authenticator webservice doesn't exist in policy
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice status

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

      - !group
        id: managers

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/managers
      member: !user alice
    """
    And I am the super-user
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "WebserviceNotFound: CONJ00005E"

    # TODO: Implement this test when we have the ability to start a Conjur server from Cucumber
#    Scenario: The authenticator is not whitelisted in environment variables
