Feature: Authenticator configuration

  Background:
    Given I have user "authn-viewer"
    And I have user "authn-updater"
    And I load a policy:
    """
    # authn-config/env is enabled in CONJUR_AUTHENTICATORS and used in tests to
    # ensure that the env value continues to be used even when DB config exists.
    - !policy
      id: conjur/authn-config/env
      body:
      - !webservice

    - !policy
      id: conjur/authn-config/db
      body:
      - !webservice

      - !webservice
        id: status

      - !group viewers

      - !permit
        role: !group viewers
        privileges: [ read ]
        resource: !webservice

      - !group updaters

      - !permit
        role: !group updaters
        privileges: [ update ]
        resource: !webservice

    - !grant
      role: !group conjur/authn-config/db/viewers
      member: !user authn-viewer

    - !grant
      role: !group conjur/authn-config/db/updaters
      member: !user authn-updater
    """

  Scenario: Authenticator is not configured in database
    When I am the super-user
    And I retrieve the list of authenticators
    Then the enabled authenticators contains "authn-config/env"

  Scenario: Authenticator is enabled in the environment and disabled in the database
    When I am the super-user
    And I successfully PATCH "/authn-config/env/cucumber" with body:
    """
    enabled=false
    """
    And I retrieve the list of authenticators
    Then the enabled authenticators contains "authn-config/env"

  Scenario: Authenticator is successfully configured
    When I login as "authn-updater"
    And I successfully PATCH "/authn-config/db/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 204
    And authenticator "cucumber:webservice:conjur/authn-config/db" is enabled

    When I successfully PATCH "/authn-config/db/cucumber" with body:
    """
    enabled=false
    """
    Then the HTTP response status code is 204
    And authenticator "cucumber:webservice:conjur/authn-config/db" is disabled

  Scenario: Authenticator account does not exist
    When I am the super-user
    And I save my place in the log file
    And I PATCH "/authn-config/db/nope" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::AccountNotDefined
    """

  Scenario: Authenticator webservice does not exist
    When I am the super-user
    And I save my place in the log file
    And I PATCH "/authn-config/db%2Fnope/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::WebserviceNotFound
    """

  Scenario: Authenticated user can not update authenticator
    When I login as "authn-viewer"
    And I save my place in the log file
    And I PATCH "/authn-config/db/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 403
    And authenticator "cucumber:webservice:conjur/authn-config/db" is disabled
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource
    """

  Scenario: Nested webservice can not be configured
    When I am the super-user
    And I save my place in the log file
    And I PATCH "/authn-config/db%2Fstatus/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthenticatorNotFound
    """
