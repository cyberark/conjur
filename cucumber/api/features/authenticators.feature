@api
Feature: Authenticator v2 Endpoints

  In this feature we define an OIDC authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the host to
  execute it, to verify not only that the host can authenticate with the OIDC
  Authenticator, but that it can retrieve a secret using the Conjur access token.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy conjur/authn-jwt
    - !policy
      id: conjur/authn-jwt/test-jwt2
      body:
        - !webservice
          annotations:
            test: 123
            other: secret
        - !variable jwks-uri
        - !group clients

    - !policy
      id: conjur/authn-jwt/test-jwt1
      body:
      - !webservice
        annotations:
          test: 123
          other: secret

      - !variable jwks-uri
      - !group users
      - !permit
        role: !group users
        privilege: [ authenticate ]
        resource: !webservice

    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !variable
        id: provider-uri

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !user alice
    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    - !grant
      role: !group conjur/authn-jwt/test-jwt1/users
      member: !user alice

    """
    And I POST "/secrets/cucumber/variable/conjur/authn-oidc/keycloak/provider-uri" with body:
    """
    https://test.com
    """

Scenario: list authenticators using the V2 Api.
  And I save my place in the audit log file for remote
  And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
  When I successfully GET "authenticators/cucumber"
  Then I receive a count of 3
  When I successfully GET "authenticators/cucumber?limit=2"
  Then I receive a count of 2
  And the authenticators list should include "test-jwt1"
  And the authenticators list should include "test-jwt2"

  Given I successfully GET "authenticators/cucumber?type=authn-oidc"
  Then I receive a count of 1
  And the authenticators list should include "keycloak"
  Then the JSON should be:
  """
  {
    "authenticators": [
      {
        "name": "keycloak",
        "annotations": {
          "description": "Authentication service for Keycloak, based on Open ID Connect."
        },
        "branch": "conjur/authn-oidc",
        "data": {
          "provider_uri": "https://test.com"
        },
        "enabled": false,
        "owner": {
          "id": "conjur/authn-oidc/keycloak",
          "kind": "policy"
        },
        "type": "oidc"
      }
    ],
    "count": 1
  }
  """
  And there is an audit record matching:
  """
  cucumber:user:admin successfully listed authenticators with URI path: '/authenticators/cucumber'
  """
  #fetchcing a single authenticator
  Given I successfully GET "authenticators/cucumber/authn-oidc/keycloak"
  Then the JSON should be:
  """
    {
      "name": "keycloak",
      "annotations": {
        "description": "Authentication service for Keycloak, based on Open ID Connect."
      },
      "branch": "conjur/authn-oidc",
      "data": {
        "provider_uri": "https://test.com"
      },
      "enabled": false,
      "owner": {
        "id": "conjur/authn-oidc/keycloak",
        "kind": "policy"
      },
      "type": "oidc"
    }
  """
  And there is an audit record matching:
  """
  cucumber:user:admin successfully retrieved authn-oidc keycloak with URI path: '/authenticators/cucumber/authn-oidc/keycloak'
  """
  # Enable authenticator
  Given I PATCH "authenticators/cucumber/authn-oidc/keycloak" with body:
  """
  { "enabled": true }
  """
  Then the JSON should be:
  """
  {
    "name": "keycloak",
    "annotations": {
      "description": "Authentication service for Keycloak, based on Open ID Connect."
    },
    "branch": "conjur/authn-oidc",
    "data": {
      "provider_uri": "https://test.com"
    },
    "enabled": true,
    "owner": {
      "id": "conjur/authn-oidc/keycloak",
      "kind": "policy"
    },
    "type": "oidc"
  }
  """
  And there is an audit record matching:
  """
  cucumber:user:admin successfully enabled authn-oidc keycloak with URI path: '/authenticators/cucumber/authn-oidc/keycloak' and JSON object: { "enabled": true }
  """
  # Disable authenticator
  Given I PATCH "authenticators/cucumber/authn-oidc/keycloak" with body:
  """
  { "enabled": false }
  """
  Then the JSON should be:
  """
  {
    "name": "keycloak",
    "annotations": {
      "description": "Authentication service for Keycloak, based on Open ID Connect."
    },
    "branch": "conjur/authn-oidc",
    "data": {
      "provider_uri": "https://test.com"
    },
    "enabled": false,
    "owner": {
      "id": "conjur/authn-oidc/keycloak",
      "kind": "policy"
    },
    "type": "oidc"
  }
  """

  Given I successfully POST "/authenticators/cucumber" with body:
  """ 
  {
    "type": "jwt",
    "name": "test-jwt3",
    "enabled": false,
    "data": {
      "jwks_uri": "http://uri",
      "identity": {
        "token_app_property": "prop",
        "enforced_claims": [ "test", "123" ],
        "claim_aliases": { "myclaim": "myvalue", "second": "two" }
      }
    },
    "annotations": {
      "test": "123"
    }
  }
  """
  And I successfully GET "authenticators/cucumber"
  Then I receive a count of 4
  Then the authenticators list should include "test-jwt3"
  When I DELETE "authenticators/cucumber/authn-jwt/test-jwt3"
  Then the HTTP response status code is 204
  And there is an audit record matching:
  """
  cucumber:user:admin successfully deleted authn-jwt test-jwt3 with URI path: '/authenticators/cucumber/authn-jwt/test-jwt3'
  """

  And I log out
  #  The api should only return authenticators alice has read access too
  When I login as "alice"
  When I successfully GET "authenticators/cucumber"
  Then I receive a count of 2
  Then the authenticators list should include "keycloak"
  Then the authenticators list should include "test-jwt1"
  Given I successfully GET "authenticators/cucumber/authn-oidc/keycloak"
  Then the JSON should be:
  """
    {
      "name": "keycloak",
      "annotations": {
        "description": "Authentication service for Keycloak, based on Open ID Connect."
      },
      "branch": "conjur/authn-oidc",
      "data": {
        "provider_uri": "https://test.com"
      },
      "enabled": false,
      "owner": {
        "id": "conjur/authn-oidc/keycloak",
        "kind": "policy"
      },
      "type": "oidc"
    }
  """
  When I GET "authenticators/cucumber/authn-jwt/test-jwt2"
  Then the HTTP response status code is 404
  And there is an audit record matching:
  """
  cucumber:user:alice failed to retrieve authn-jwt test-jwt2 with URI path: '/authenticators/cucumber/authn-jwt/test-jwt2'
  """
  When I DELETE "authenticators/cucumber/authn-jwt/test-jwt2"
  Then the HTTP response status code is 404
  And there is an audit record matching:
  """
  cucumber:user:alice failed to delete authn-jwt test-jwt2 with URI path: '/authenticators/cucumber/authn-jwt/test-jwt2': Authenticator: test-jwt2 not found in account 'cucumber'
  """
