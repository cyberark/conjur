Feature: Authenticator status check

  Scenario: A healthy authenticator returns a successful response
    Given a policy:
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

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/managers
      member: !user alice
    """
    And I am the super-user
    And I successfully set OIDC variables
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 200
    And the authenticator status check succeeds

  Scenario: An unauthorized user is responded with 403
    Given a policy:
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

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I am the super-user
    And I successfully set OIDC variables
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 403
    And the authenticator status check fails with error "#<Errors::Authentication::Security::UserNotAuthorizedInConjur: CONJ00006E User 'alice' is not authorized in the Conjur policy>"

  Scenario: An authenticator without an implemented status check returns 503
    Given I login as "alice"
    When I GET "/authn-ldap/test/cucumber/status"
    Then the HTTP response status code is 501
    And the authenticator status check fails with error "#<Errors::Authentication::StatusNotImplemented: CONJ00045E Status check not implemented for authenticator 'authn-ldap'>"

  Scenario: A non-existing authenticator status check returns 404
    Given I login as "alice"
    When I GET "/authn-nonexist/test/cucumber/status"
    Then the HTTP response status code is 404
    And the authenticator status check fails with error "#<Errors::Authentication::AuthenticatorNotFound: CONJ00001E Authenticator 'authn-nonexist' is not implemented in Conjur>"

  Scenario: A missing status webservice returns 500
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
    And the authenticator status check fails with error "#<Errors::Authentication::Security::ServiceNotDefined: CONJ00005E Webservice 'authn-oidc/keycloak/status' is not defined in the Conjur policy>"

  Scenario: A non-existing account name in the status request returns 500
    Given a policy:
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

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/managers
      member: !user alice
    """
    And I am the super-user
    And I successfully set OIDC variables
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/non-existing-account/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "#<Errors::Authentication::Security::AccountNotDefined: CONJ00008E Account 'non-existing-account' is not defined in Conjur>"

  Scenario: An authenticator webservice doesn't exist in policy
    Given a policy:
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
    And I successfully set OIDC variables
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "#<Errors::Authentication::Security::ServiceNotDefined: CONJ00005E Webservice 'authn-oidc/keycloak' is not defined in the Conjur policy>"

    # TODO: Implement this test when we have the ability to start a Conjur server from Cucumber
#    Scenario: The authenticator is not whitelisted in environment variables