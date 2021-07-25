Feature: JWT Authenticator - Validate And Decode

  Tests checking tokens signed with wrong keys.

  Background:
    Given I load a policy:
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
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I initialize JWKS endpoint with file "myJWKs.json"

  Scenario: ONYX-8732: Signature error, kid not found
    Given I issue unknown kid JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
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

  Scenario: ONYX-8733: Signature error ,sign on a valid token header and content with your own key
    Given I issue another key JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
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

