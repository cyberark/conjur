Feature: Dynamically generated secrets.

  A Conjur "webservice" can be configured with annotation "credential-factory/provider". 
  This provider identifies an algorithm which will generate a value (normally, a credential),
  which can be accessed through the route "GET /secrets/:account/webservice/:id".

  In effect, this is a dynamically generated value which is obtained through the same URL route
  as a statically stored secret. As with statically stored secret in a variable, "execute" privilege on the 
  webservice is required to obtain the generated value.

  The "credential-factory/provider" algorithm may use other secrets in order to perform its function.
  For example, a credential factory which issues temporary cloud access credentials requires 
  static cloud credentials in order to call the cloud API. This relationship between the credential factory
  webservice and its dependent variables is managed using annotations.

  To prevent unauthorized use of statically stored credentials, the credential
  factory webservice must have "execute" permission on any variables which it tries to use.

  Background:
    Given I am the super-user

  Scenario: An authorized role can obtain a value.
  
    Given I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !webservice
      id: uuid
      annotations:
        credential-factory/provider: uuid
    """
    When I successfully GET "/secrets/cucumber/webservice/uuid"
    Then I receive 1 response
    And the first text response looks like a UUID

  Scenario: An unauthorized role cannot obtain a value.

    Given I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice

    - !webservice
      id: uuid
      annotations:
        credential-factory/provider: uuid
    """
    And I login as "alice"
    When I GET "/secrets/cucumber/webservice/uuid"
    Then the HTTP response status code is 403

  Scenario: Properly configured annotations enable a credential factory to depend on other variables.
    Given I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !variable password

    - !webservice
      id: echo
      annotations:
        credential-factory/provider: echo
        credential-factory/variable: password

    - !permit
      role: !webservice echo
      privileges: execute
      resource: !variable password
    """
    And I successfully POST "/secrets/cucumber/variable/password" with body:
    """
    the-password
    """
    When I successfully GET "/secrets/cucumber/webservice/echo"
    Then the JSON should be:
    """
    [ "the-password" ]
    """

  Scenario: A missing required annotation is reported as an error.
    Given I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !webservice
      id: echo
      annotations:
        credential-factory/provider: echo
    """
    When I GET "/secrets/cucumber/webservice/echo"
    Then the HTTP response status code is 422
    And the JSON should be:
    """
    {
      "error": {
        "code": "argument_error",
        "message": "Annotation \"credential-factory/variable\" is required"
      }
    } 
    """

  Scenario: A reference to a non-existent dependency variable is reported as an error.
    Given I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !webservice
      id: echo
      annotations:
        credential-factory/provider: echo
        credential-factory/variable: password
    """
    When I GET "/secrets/cucumber/webservice/echo"
    Then the HTTP response status code is 404
    And the JSON should be:
    """
    {
      "error": {
        "code": "not_found",
        "message": "Variable 'password' not found in account 'cucumber'",
        "target": "variable",
        "details": {
          "code": "not_found",
          "target": "id",
          "message": "cucumber:variable:password"
        }
      }
    }    
    """

  Scenario: Insufficient authorization to a dependency variable is reported as an error.
    Given I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !variable password

    - !webservice
      id: echo
      annotations:
        credential-factory/provider: echo
        credential-factory/variable: password
    """
    When I GET "/secrets/cucumber/webservice/echo"
    Then the HTTP response status code is 403
    And the JSON should be:
    """
    {
      "error": {
        "code": "forbidden",
        "message": "\"cucumber:webservice:echo\" does not have 'execute' privilege on \"cucumber:variable:password\""
      }
    }
    """

  Scenario: Missing value in a dependency variable is reported as an error.
    Given I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !variable password

    - !webservice
      id: echo
      annotations:
        credential-factory/provider: echo
        credential-factory/variable: password

    - !permit
      role: !webservice echo
      privileges: execute
      resource: !variable password
    """
    When I GET "/secrets/cucumber/webservice/echo"
    Then the HTTP response status code is 404
    And the JSON should be:
    """
    {
      "error": {
        "code": "not_found",
        "message": "\"cucumber:variable:password\" does not contain a secret value",
        "target": "variable",
        "details": {
          "code": "not_found",
          "target": "id",
          "message": "cucumber:variable:password"
        }
      }
    }
    """
