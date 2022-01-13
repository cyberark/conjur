@authenticators_config
Feature: Authenticator configuration

  Background:
    Given I have user "authn-viewer"
    And I have user "authn-updater"
    And I load a policy:
    """
    # authn-k8s/test is enabled in CONJUR_AUTHENTICATORS and used in tests to
    # ensure that the env value continues to be used even when DB config exists.
    - !policy
      id: conjur/authn-k8s/test
      body:
      - !webservice

    - !policy
      id: conjur/authn-k8s/db
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
      role: !group conjur/authn-k8s/db/viewers
      member: !user authn-viewer

    - !grant
      role: !group conjur/authn-k8s/db/updaters
      member: !user authn-updater
    """

  @smoke
  Scenario: Authenticator is not configured in database
    When I am the super-user
    And I retrieve the list of authenticators
    Then the enabled authenticators contains "authn-k8s/test"

  @smoke
  Scenario: Authenticator is enabled in the environment and disabled in the database
    When I am the super-user
    And I successfully PATCH "/authn-k8s/test/cucumber" with body:
    """
    enabled=false
    """
    And I retrieve the list of authenticators
    Then the enabled authenticators contains "authn-k8s/test"

  @smoke
  Scenario: Authenticator is successfully configured
    When I login as "authn-updater"
    And I successfully PATCH "/authn-k8s/db/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 204
    And authenticator "cucumber:webservice:conjur/authn-k8s/db" is enabled

    When I successfully PATCH "/authn-k8s/db/cucumber" with body:
    """
    enabled=false
    """
    Then the HTTP response status code is 204
    And authenticator "cucumber:webservice:conjur/authn-k8s/db" is disabled

  @negative @acceptance
  Scenario: Authenticator account does not exist
    When I am the super-user
    And I save my place in the log file
    And I PATCH "/authn-k8s/db/nope" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::AccountNotDefined
    """

  @negative @acceptance
  Scenario: Authenticator webservice does not exist
    When I am the super-user
    And I save my place in the log file
    And I PATCH "/authn-k8s/db%2Fnope/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::WebserviceNotFound
    """

  @negative @acceptance
  Scenario: Authenticated user can not update authenticator
    When I login as "authn-viewer"
    And I save my place in the log file
    And I PATCH "/authn-k8s/db/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 403
    And authenticator "cucumber:webservice:conjur/authn-k8s/db" is disabled
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource
    """

  @negative @acceptance
  Scenario: Nested webservice can not be configured
    When I am the super-user
    And I save my place in the log file
    And I PATCH "/authn-k8s/db%2Fstatus/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthenticatorNotSupported
    """

  @smoke
  Scenario: Authenticator without service-id is successfully configured
    When I am the super-user
    And I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
      body:
      - !webservice
    """
    And I save my place in the log file
    And I PATCH "/authn-gcp/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 204
    And authenticator "cucumber:webservice:conjur/authn-gcp" is enabled

    When I successfully PATCH "/authn-gcp/cucumber" with body:
    """
    enabled=false
    """
    Then the HTTP response status code is 204
    And authenticator "cucumber:webservice:conjur/authn-gcp" is disabled

  @negative @acceptance
  Scenario: Authenticator without service-id and webservice does not exist
    When I am the super-user
    And I save my place in the log file
    And I PATCH "/authn-gcp/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::WebserviceNotFound
    """
    And authenticator "cucumber:webservice:conjur/authn-gcp" is disabled

    When I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
    """
    And I save my place in the log file
    And I PATCH "/authn-gcp/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::WebserviceNotFound
    """
    And authenticator "cucumber:webservice:conjur/authn-gcp" is disabled

  @negative @acceptance
  Scenario: Unauthorized user can not update authenticator without service-id
    When I am the super-user
    And I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
      body:
      - !webservice
    """
    When I login as "authn-viewer"
    And I save my place in the log file
    And I PATCH "/authn-gcp/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 403
    And authenticator "cucumber:webservice:conjur/authn-gcp" is disabled
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource
    """

  @negative @acceptance
  Scenario: Nested webservice can not be configured for authenticator without service-id
    When I am the super-user
    And I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
      body:
      - !webservice
    """
    And I save my place in the log file
    And I PATCH "/authn-gcp/myservice/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::WebserviceNotFound
    """
    And I save my place in the log file
    And I PATCH "/authn-gcp/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 204
