@ipv6
Feature: JWT Authenticator (IPv6) - Check registered claim

  Verify the authenticator works correctly with the registered claims:
   - iat
   - exp
   - nbf
   - iss
   - aud

  Background:
    Given I initialize remote JWKS endpoint with file "authn-jwt-check-standard-claims" and alg "RS256"
    And I load a policy:
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

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I set the following conjur variables:
      | variable_id                                   | default_value |
      | conjur/authn-jwt/keycloak/token-app-property  | host          |
      | conjur/authn-jwt/raw/token-app-property       | host          |

    And I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I permit host "alice" to "execute" it

  @acceptance
  Scenario: ONYX-8727: Issuer configured with incorrect value, iss claim not exists in token, 200 ok
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: issuer
    """
    And I set the following conjur variables:
      | variable_id                         | default_value                                             |
      | conjur/authn-jwt/raw/jwks-uri       | http://jwks_py:8090/authn-jwt-check-standard-claims/RS256 |
      | conjur/authn-jwt/raw/issuer         | incorrect-value                                       |

    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @acceptance
  Scenario: ONYX-8728: jwks-uri configured with correct value, issuer configured with correct value, iss claim with correct value, 200 OK
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: issuer
    """
    And I set the following conjur variables:
      | variable_id                   | default_value                                             |
      | conjur/authn-jwt/raw/jwks-uri | http://jwks_py:8090/authn-jwt-check-standard-claims/RS256 |
      | conjur/authn-jwt/raw/issuer   | http://jwks                                               |

    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "http://jwks"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @sanity
  @acceptance
  Scenario Outline: Audience tests
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/jwks-uri
    - !variable conjur/authn-jwt/raw/audience

    - !host
      id: aud-test-app
      annotations:
        authn-jwt/raw/project_id: valid-project-id

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host aud-test-app
    """
    And I set the following conjur variables:
      | variable_id                   | default_value                                             |
      | conjur/authn-jwt/raw/jwks-uri | http://jwks_py:8090/authn-jwt-check-standard-claims/RS256 |
      | conjur/authn-jwt/raw/audience | <audience>                                                |

    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "project_id":"valid-project-id",
      "host":"aud-test-app",
      <aud>
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is <http_code>
    And The following appears in the log after my savepoint:
    """
    <log>
    """
    Examples:
      | Test       | audience        | aud                                         | http_code | log                                                                                                                                       |
      | ONYX-11154 | valid-audience  | "other":"claim"                             | 401       | CONJ00091E Failed to validate token: mandatory claim 'aud' is missing.                                                                    |
      | ONYX-11156 | valid-audience  | "aud":"invalid"                             | 401       | CONJ00018D Failed to decode the token with the error '#<JWT::InvalidAudError: Invalid audience. Expected valid-audience, received invalid |
      | ONYX-11158 | valid-audience  | "aud": ["value1","valid-audience","value2"] | 200       | cucumber:host:aud-test-app successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw       |
