@authenticators_jwt
Feature: JWT Authenticator - Validate And Decode

  Tests checking tokens signed with wrong keys.

  Background:
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
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I initialize JWKS endpoint with file "myJWKs.json"

  @negative @acceptance
  Scenario: ONYX-8732: Signature error, kid not found
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/jwks-uri
    """
    And I issue unknown kid JWT token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::DecodeError: Could not find public key for kid unknown_kid>')>
    """


  @sanity
  @negative @acceptance
  Scenario: ONYX-8733: Signature error, sign on a valid token header and content with your own key
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/jwks-uri
    """
    And I issue another key JWT token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::VerificationError: Signature verification raised>')>
    """

  @negative @acceptance
  Scenario: ONYX-15324: public-keys with valid issuer, token is signed by other key
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/public-keys
    - !variable conjur/authn-jwt/raw/issuer
    """
    And I successfully set authn-jwt public-keys variable with value from "myJWKs.json" endpoint
    And I successfully set authn-jwt "issuer" variable to value "valid-issuer"
    And I issue another key JWT token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "valid-issuer"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::VerificationError: Signature verification raised>')>
    """
