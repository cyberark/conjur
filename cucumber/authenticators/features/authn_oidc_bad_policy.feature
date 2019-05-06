Feature: Users can authenticate with OIDC authenticator

  Scenario: id-token-user-property variable missing in policy is denied
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
    And I successfully set provider-uri variable
    Given I get authorization code for username "alice" and password "alice"
    And I fetch an ID Token
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequiredResourceMissing
    """

  Scenario: provider-uri variable missing in policy is denied
    Given a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

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
    And I successfully set id-token-user-property variable
    Given I get authorization code for username "alice" and password "alice"
    And I fetch an ID Token
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequiredResourceMissing
    """

  Scenario: webservice missing in policy is denied
    Given a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I am the super-user
    And I successfully set OIDC variables
    Given I get authorization code for username "alice" and password "alice"
    And I fetch an ID Token
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::ServiceNotDefined
    """

  Scenario: webservice with read and no authenticate permission in policy is denied
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
          privilege: [ read ]
          resource: !webservice

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I am the super-user
    And I successfully set OIDC variables
    Given I get authorization code for username "alice" and password "alice"
    And I fetch an ID Token
    And I save my place in the log file
    When I authenticate via OIDC with id token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::UserNotAuthorizedInConjur
    """
