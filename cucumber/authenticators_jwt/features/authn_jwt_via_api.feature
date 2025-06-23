@authenticators_jwt
Feature: JWT Authenticator - JWKs Basic sanity

  In this feature we define a JWT authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the host to
  execute it.

  Background:
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I initialize remote JWKS endpoint with file "authn-jwt-general" and alg "RS256"
    Given I successfully initialize a JWT authenticator named "jwt-authenticator" via the authenticators API
    When I load a policy:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/jwt-authenticator/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/jwt-authenticator/apps
      member: !host myapp
      """

  @acceptance
  Scenario: Authenticator is configured properly
    Given I have a "variable" resource called "test-variable"
    And I am using file "authn-jwt-general" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "jwks_py"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with jwt-authenticator service ID
    Then the HTTP response status code is 401
