Feature: JWT Authenticator - Fetch signing key

  Scenario: provider-uri is configured with valid value
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on Keycloak as OIDC provider.

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !variable
        id: issuer

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice

    - !host
      id: alice
      annotations:
        authn-jwt/keycloak/email: alice@conjur.net

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host alice
    """
    And I am the super-user
    And I successfully set authn-jwt "provider-uri" variable with OIDC value from env var "PROVIDER_URI"
    And I successfully set authn-jwt "token-app-property" variable with OIDC value from env var "ID_TOKEN_USER_PROPERTY"
    And I successfully set authn-jwt "issuer" variable with OIDC value from env var "PROVIDER_ISSUER"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via authn-jwt with the ID token
    Then host "alice" has been authorized by Conjur

  Scenario: provider uri configured with bad value
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

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
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp

    - !host
      id: some_policy/sub_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/sub_policy/host_test_from_token

    - !host
      id: some_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/host_test_from_token
    """
    And I am the super-user
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "provider-uri" variable to value "unknown-host.com"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 502
    And The following appears in the log after my savepoint:
    """
    CONJ00011E Failed to discover Identity Provider
    """

  Scenario: jwks uri configured with valid value
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

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
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp

    - !host
      id: some_policy/sub_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/sub_policy/host_test_from_token

    - !host
      id: some_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/host_test_from_token
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: jwks uri configured with bad value
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

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
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp

    - !host
      id: some_policy/sub_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/sub_policy/host_test_from_token

    - !host
      id: some_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/host_test_from_token
    """
    And I am the super-user
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "jwks-uri" variable to value "unknown-host.com"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00087E Failed to fetch JWKS from 'unknown-host.com'
    """

  Scenario: provider uri configured dynamically changed to jwks uri
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on keycloak JWKs.

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !variable
        id: issuer

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice

    - !host
      id: myapp
      annotations:
        authn-jwt/keycloak/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host myapp

    - !host
      id: alice
      annotations:
        authn-jwt/keycloak/email: alice@conjur.net

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host alice
    """
    And I am the super-user
    And I successfully set authn-jwt "provider-uri" variable with OIDC value from env var "PROVIDER_URI"
    And I successfully set authn-jwt "token-app-property" variable with OIDC value from env var "ID_TOKEN_USER_PROPERTY"
    And I successfully set authn-jwt "issuer" variable with OIDC value from env var "PROVIDER_ISSUER"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    And I authenticate via authn-jwt with the ID token
    And host "alice" has been authorized by Conjur
    When I update the policy with:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !delete
        record: !variable provider-uri
    """
    And I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !variable
        id: jwks-uri
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" in service "keycloak"
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable value to "host" in service "keycloak"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    And I authenticate via authn-jwt using given keycloak service ID and without account in url
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/keycloak
    """

  Scenario: jwks uri configured dynamically changed to provider uri
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on keycloak JWKs.

      - !variable
        id: jwks-uri

      - !variable
        id: token-app-property

      - !variable
        id: issuer

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice

    - !host
      id: myapp
      annotations:
        authn-jwt/keycloak/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host myapp

    - !host
      id: alice
      annotations:
        authn-jwt/keycloak/email: alice@conjur.net

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host alice
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" in service "keycloak"
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable value to "host" in service "keycloak"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    And I authenticate via authn-jwt using given keycloak service ID and without account in url
    And host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/keycloak
    """
    When I update the policy with:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !delete
        record: !variable jwks-uri
    """
    And I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !variable
        id: provider-uri
    """
    And I am the super-user
    And I successfully set authn-jwt "provider-uri" variable with OIDC value from env var "PROVIDER_URI"
    And I successfully set authn-jwt "token-app-property" variable with OIDC value from env var "ID_TOKEN_USER_PROPERTY"
    And I successfully set authn-jwt "issuer" variable with OIDC value from env var "PROVIDER_ISSUER"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    And I authenticate via authn-jwt with the ID token
    Then host "alice" has been authorized by Conjur

  Scenario: provider-uri dynamically changed, 502 ERROR resolves to 200 OK
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on keycloak JWKs.

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !variable
        id: issuer

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice

    - !host
      id: myapp
      annotations:
        authn-jwt/keycloak/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host myapp

    - !host
      id: alice
      annotations:
        authn-jwt/keycloak/email: alice@conjur.net

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host alice
    """
    And I am the super-user
    And I successfully set authn-jwt "provider-uri" variable in keycloack service to "incorrect.com"
    And I successfully set authn-jwt "token-app-property" variable with OIDC value from env var "ID_TOKEN_USER_PROPERTY"
    And I successfully set authn-jwt "issuer" variable with OIDC value from env var "PROVIDER_ISSUER"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    And I authenticate via authn-jwt with the ID token
    And the HTTP response status code is 502
    And The following appears in the log after my savepoint:
    """
    CONJ00011E Failed to discover Identity Provider (Provider URI: 'incorrect.com'). Reason: '#<AttrRequired::AttrMissing: 'host' required.>'
    """
    And I successfully set authn-jwt "provider-uri" variable with OIDC value from env var "PROVIDER_URI"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via authn-jwt with the ID token
    Then host "alice" has been authorized by Conjur

  Scenario: jwks-uri dynamically changed, 401 ERROR resolves 200 OK
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

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
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I successfully set authn-jwt "jwks-uri" variable to value "incorrect.com"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    And I authenticate via authn-jwt with raw service ID
    And the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00087E Failed to fetch JWKS from 'incorrect.com'
    """
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """
