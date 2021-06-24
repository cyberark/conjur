Feature: JWT Authenticator - JWKs fetched from Keycloak as OIDC provider

  In this feature we define a JWT authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the host to
  execute it.

  Background:
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

  Scenario: provider-uri is configured with valid value
    Given I am the super-user
    And I successfully set authn-jwt "provider-uri" variable with OIDC value from env var "PROVIDER_URI"
    And I successfully set authn-jwt "token-app-property" variable with OIDC value from env var "ID_TOKEN_USER_PROPERTY"
    And I successfully set authn-jwt "issuer" variable with OIDC value from env var "PROVIDER_ISSUER"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    When I authenticate via authn-jwt with the ID token
    Then host "alice" has been authorized by Conjur
    And The following lines appear in the log after my savepoint:
      |                                                                                                 |
      |CONJ00076I Selected signing key interface: 'provider-uri'                                        |
      |CONJ00072I Fetching JWKS from 'https://keycloak:8443/auth/realms/master'...                      |
      |CONJ00054I "issuer" value will be taken from 'cucumber:variable:conjur/authn-jwt/keycloak/issuer'|
      |CONJ00055I Retrieved "issuer" with value 'http://keycloak:8080/auth/realms/master'               |
      |CONJ00098I Successfully found JWT identity 'host/alice'                                          |


  Scenario: provider-uri dynamically changed, 502 ERROR resolves to 200 OK
    Given I am the super-user
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
    When I successfully set authn-jwt "provider-uri" variable with OIDC value from env var "PROVIDER_URI"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the log file
    And I authenticate via authn-jwt with the ID token
    Then host "alice" has been authorized by Conjur
    And The following lines appear in the log after my savepoint:
      |                                                                                                 |
      |CONJ00076I Selected signing key interface: 'provider-uri'                                        |
      |CONJ00072I Fetching JWKS from 'https://keycloak:8443/auth/realms/master'...                      |
      |CONJ00054I "issuer" value will be taken from 'cucumber:variable:conjur/authn-jwt/keycloak/issuer'|
      |CONJ00055I Retrieved "issuer" with value 'http://keycloak:8080/auth/realms/master'               |
      |CONJ00098I Successfully found JWT identity 'host/alice'                                          |
