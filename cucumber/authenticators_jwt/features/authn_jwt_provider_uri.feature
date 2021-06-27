

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
