@authenticators_jwt
Feature: JWT Authenticator - Fetch signing key

  In this feature we define a JWT authenticator with various signing key
  configurations.

  @sanity
  @smoke
  Scenario: ONYX-8702: provider-uri is configured with valid value
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice

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

  @negative @acceptance
  Scenario: ONYX-8704: provider uri configured with bad value
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
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
      id: alice
      annotations:
        authn-jwt/keycloak/email: alice@conjur.net

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host alice
    """
    And I am the super-user
    And I successfully set authn-jwt "provider-uri" variable value to "unknown-host.com" in service "keycloak"
    And I successfully set authn-jwt "token-app-property" variable value to "host" in service "keycloak"
    And I save my place in the log file
    And I fetch an ID Token for username "alice" and password "alice"
    When I authenticate via authn-jwt with the ID token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00011E Failed to discover Identity Provider (Provider URI: 'unknown-host.com')
    """

  @negative @acceptance
  Scenario: ONYX-8705: jwks uri configured with bad value
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
    And I initialize remote JWKS endpoint with file "authn-jwt-fetch-signing-key" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable to value "unknown-host.com"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I am using file "authn-jwt-fetch-signing-key" and alg "RS256" for remotely issue token:
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
    CONJ00087E Failed to fetch JWKS from 'unknown-host.com'
    """

  @acceptance
  Scenario: ONYX-8708: provider uri configured dynamically changed to jwks uri
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice

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
    And I authenticate via authn-jwt with the ID token
    And host "alice" has been authorized by Conjur
    When I replace the "root" policy with:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
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
      id: alice
      annotations:
        authn-jwt/keycloak/email: alice@conjur.net

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host alice
    """
    And I am the super-user
    And I initialize remote JWKS endpoint with file "authn-jwt-fetch-signing-key" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-fetch-signing-key/RS256" in service "keycloak"
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable value to "host" in service "keycloak"
    And I permit host "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "authn-jwt-fetch-signing-key" and alg "RS256" for remotely issue token:
    """
    {
      "host":"alice",
      "project_id": "myproject",
      "email": "alice@conjur.net"
    }
    """
    And I save my place in the log file
    And I authenticate via authn-jwt using given keycloak service ID and without account in url
    Then host "alice" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:alice successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/keycloak
    """

  @acceptance
  Scenario: jwks uri configured dynamically changed to provider uri
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
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
      id: alice
      annotations:
        authn-jwt/keycloak/email: alice@conjur.net

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host alice
    """
    And I am the super-user
    And I initialize remote JWKS endpoint with file "authn-jwt-fetch-signing-key" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-fetch-signing-key/RS256" in service "keycloak"
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable value to "host" in service "keycloak"
    And I permit host "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "authn-jwt-fetch-signing-key" and alg "RS256" for remotely issue token:
    """
    {
      "host":"alice",
      "project_id": "myproject",
      "email": "alice@conjur.net"
    }
    """
    And I save my place in the log file
    And I authenticate via authn-jwt using given keycloak service ID and without account in url
    And host "alice" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:alice successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/keycloak
    """
    When I replace the "root" policy with:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice

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
    And I authenticate via authn-jwt with the ID token
    Then host "alice" has been authorized by Conjur

  @sanity
  @acceptance
  Scenario: ONYX-8709: provider-uri dynamically changed, 502 ERROR resolves to 200 OK
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice

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
    And the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00011E Failed to discover Identity Provider (Provider URI: 'incorrect.com'). Reason: '#<AttrRequired::AttrMissing: 'host' required.>'
    """
    And I successfully set authn-jwt "provider-uri" variable with OIDC value from env var "PROVIDER_URI"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via authn-jwt with the ID token
    Then host "alice" has been authorized by Conjur

  @sanity
  @acceptance
  Scenario: ONYX-8710: jwks-uri dynamically changed, 401 ERROR resolves 200 OK
    Given I initialize remote JWKS endpoint with file "authn-jwt-fetch-signing-key" and alg "RS256"
    And I load a policy:
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
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I successfully set authn-jwt "jwks-uri" variable to value "incorrect.com"
    And I am using file "authn-jwt-fetch-signing-key" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    And I authenticate via authn-jwt with raw service ID
    And the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00087E Failed to fetch JWKS from 'incorrect.com'
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-fetch-signing-key/RS256" in service "raw"
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @negative @acceptance
  Scenario: ONYX-8853: jku is unfollowed - security check
    Given I initialize JWKS endpoint with file "myFirstJWKs.json"
    And I initialize JWKS endpoint "mySecondJWKs.json" with the same kid as "myFirstJWKs.json"
    And I load a policy:
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
    And I successfully set authn-jwt jwks-uri variable with value of "myFirstJWKs.json" endpoint
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I issue a JWT token signed with jku with jwks file_name "mySecondJWKs.json":
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
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::VerificationError: Signature verification raised>')
    """

  @negative @acceptance
  Scenario: ONYX-8854: jwk is unfollowed - security check
    Given I initialize JWKS endpoint with file "myFirstJWKs.json"
    And I initialize JWKS endpoint "localRsaKey.json" with the same kid as "myFirstJWKs.json"
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
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myFirstJWKs.json" endpoint
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I issue a JWT token signed with jwk with jwks file_name "localRsaKey.json":
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
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::VerificationError: Signature verification raised>')
    """

  @negative @acceptance
  Scenario: ONYX-8914: provider-uri with untrusted self sign certificate
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice

      - !variable
        id: provider-uri
    """
    And I am the super-user
    And I successfully set authn-jwt "provider-uri" variable value to "https://jwks" in service "keycloak"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via authn-jwt with the ID token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00011E Failed to discover Identity Provider (Provider URI: 'https://jwks'). Reason: '#<OpenIDConnect::Discovery::DiscoveryFailed: SSL_connect returned=1 errno=0 state=error: certificate verify failed (self signed certificate)>
    """

  @negative @acceptance
  Scenario: ONYX-8913: jwks-uri with untrusted self sign certificate
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri
    """
    And I am the super-user
    And I initialize JWKS endpoint with file "JWKs.json"
    And I successfully set authn-jwt "jwks-uri" variable value to "https://jwks" in service "raw"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00087E Failed to fetch JWKS from 'https://jwks'. Reason: '#<OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=error: certificate verify failed (self signed certificate)>'>
    """

  @negative @acceptance
  Scenario: ONYX-8856: x5c header claim is ignored
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri
    """
    And I am the super-user
    And I initialize JWKS endpoint with file "JWKS.json"
    And I successfully set authn-jwt jwks-uri variable with value of "JWKS.json" endpoint
    And I issue a JWT token signed with self-signed certificate with x5c:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::DecodeError: No key id (kid) found from token headers>')
    """

  @negative @acceptance
  Scenario: ONYX-8855: x5u header claim is ignored
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri
    """
    And I am the super-user
    And I initialize JWKS endpoint with file "JWKS.json"
    And I successfully set authn-jwt jwks-uri variable with value of "JWKS.json" endpoint
    And I issue a JWT token signed with self-signed certificate with x5u with file name "x5u.pem":
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::DecodeError: No key id (kid) found from token headers>')
    """

  @sanity
  @smoke
  Scenario: ONYX-15322: public-keys happy path
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
      - !variable public-keys
      - !variable issuer
      - !variable token-app-property

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
    And I initialize remote JWKS endpoint with file "public-key-1" and alg "RS256"
    And I successfully set authn-jwt public-keys variable to value from remote JWKS endpoint "public-key-1" and alg "RS256"
    And I successfully set authn-jwt "issuer" variable to value "valid-issuer"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I am using file "public-key-1" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "valid-issuer"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @negative @acceptance
  Scenario: ONYX-15325: public-keys value is in invalid format
    Given I load a policy:
     """
     - !policy
       id: conjur/authn-jwt/raw
       body:
       - !webservice
       - !variable public-keys
       - !variable issuer
       - !webservice status
     """
    And I am the super-user
    And I successfully set authn-jwt "public-keys" variable to value "{ }"
    And I successfully set authn-jwt "issuer" variable to value "valid-issuer"
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00120E Failed to parse 'public-keys': Type can't be blank, Value can't be blank, and Type '' is not a valid public-keys type. Valid types are: jwks"

  @negative @acceptance
  Scenario: JWKS URI with bad value and no issuer - Status And Authentication return same error
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

      - !webservice
        id: status
        annotations:
          description: Status service to check that the authenticator is configured correctly

      - !group
          id: operators
          annotations:
            description: Group of users who can check the status of the authenticator

      - !permit
        role: !group operators
        privilege: [ read ]
        resource: !webservice status

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable to value "unknown-host.com"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I am using file "authn-jwt-fetch-signing-key" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00087E Failed to fetch JWKS from 'unknown-host.com'"
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00087E Failed to fetch JWKS from 'unknown-host.com'
    """
