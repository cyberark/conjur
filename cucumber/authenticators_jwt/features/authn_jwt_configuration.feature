@authenticators_jwt
Feature: JWT Authenticator - Configuration Check

  Tests to check failures because of misconfiguration of the JWT during runtime.

  Background:
    Given I initialize remote JWKS endpoint with file "authn-jwt-configuration" and alg "RS256"
    And I have a "variable" resource called "test-variable"

  @negative @acceptance
  Scenario: ONYX-8600: Webservice is missing in Authenticator policy
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: token-app-property

      - !group hosts
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00005E Webservice 'authn-jwt/raw' not found
    """

  @negative @acceptance
  Scenario: ONYX-8601: Webservice with read and no authenticate permission in authenticator policy
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

      - !variable
        id: token-app-property

      - !group hosts
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 403
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'host/myapp' does not have 'authenticate' privilege on cucumber:webservice:conjur/authn-jwt/raw
    """

  @negative @acceptance
  Scenario: ONYX-8694: Both provider-uri and jwks-uri are configured
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable to value "jwks uri placehodlder"
    And I successfully set authn-jwt "provider-uri" variable to value "provider uri placeholder"
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00122E Invalid signing key settings: jwks-uri and provider-uri cannot be defined simultaneously
    """

  @negative @acceptance
  Scenario: ONYX-8826: provider-uri configured with correct value, jwks-uri configured with empty value, error
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable to value " "
    And I successfully set authn-jwt "provider-uri" variable to value "provider uri placeholder"
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00122E Invalid signing key settings: jwks-uri and provider-uri cannot be defined simultaneously
    """

  @negative @acceptance
  Scenario: ONYX-8698: jwks-uri configured but variable not set
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/jwks-uri
    """

  @negative @acceptance
  Scenario: ONYX-8697: provider-uri configured but variable not set
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/provider-uri
    """

  @negative @acceptance
  Scenario: ONYX-8696: None of provider-uri or jwks-uri are configured
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00122E Invalid signing key settings: One of the following must be defined: jwks-uri, public-keys, or provider-uri
    """

  @negative @acceptance
  Scenario: ONYX-8695: provider-uri configured with empty value, jwks-uri configured with correct value
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "provider-uri" variable to value " "
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00122E Invalid signing key settings: jwks-uri and provider-uri cannot be defined simultaneously
    """

  @negative @acceptance
  Scenario: ONYX-8694: Both Token identity and host send in URL, error
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with myapp account in url
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnJwt::IdentityMisconfigured: CONJ00098E JWT identity configuration is invalid
    """

  @negative @acceptance
  Scenario: ONYX-8602: Host in token not defined , and no host in URL, error
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I am using file "authn-jwt-configuration" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00098E JWT identity configuration is invalid
    """
