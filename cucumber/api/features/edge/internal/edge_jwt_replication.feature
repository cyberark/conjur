@api @sanity @smoke
Feature: Replicate jwt authenticators from edge endpoint

  Background:
    Given I clear Redis cache
    Given I create a new user "some_user"
    And I create a new user "admin_user"
    And I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: edge
      body:
        - !group edge-hosts
        - !group edge-installer-group
        - !policy
            id: edge-configuration
            body:
              - &edge-variables
                - !variable max-edge-allowed
    - !policy
      id: conjur/authn-jwt/myVendor
      body:
        - !webservice
        - !variable jwks-uri
        - !variable ca-cert
        - !variable token-app-property
        - !variable identity-path
        - !variable issuer
        - !variable enforced-claims
        - !variable claim-aliases
        - !variable audience
        - !group apps
        - !permit
          role: !group apps
          privilege: [read, authenticate]
          resource: !webservice
        - !webservice status
        - !group operators
        - !permit
          role: !group operators
          privilege: [read]
          resource: !webservice status
    - !policy
      id: conjur/authn-jwt/withoutPermissions
      body:
        - !webservice
        - !variable jwks-uri
        - !variable ca-cert
        - !variable enforced-claims
        - !variable claim-aliases
    - !policy
      id: conjur/authn-jwt/bestAuthenticator
      body:
        - !webservice
        - !variable jwks-uri
        - !variable ca-cert

    - !group Conjur_Cloud_Admins
    - !grant
      role: !group Conjur_Cloud_Admins
      member: !user admin_user
    """
    And I add the secret value "https://www.googleapis.com/oauth2/v3/certs" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/jwks-uri"
    And I add the secret value "app_name" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/token-app-property"
    And I add the secret value "data/myspace/jwt-apps" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/identity-path"
    And I add the secret value "https://login.example.com" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/issuer"
    And I add the secret value "additional_data/group_id" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/enforced-claims"
    And I add the secret value "google/claim,azure/claim," to the resource "cucumber:variable:conjur/authn-jwt/myVendor/enforced-claims"
    And I add the secret value "claim:google/claim,,myclaim:,myclaim::azure/claim," to the resource "cucumber:variable:conjur/authn-jwt/myVendor/claim-aliases"
    And I successfully PATCH "/authn-jwt/myVendor/cucumber" with body:
    """
    enabled=true
    """
    Given I add the secret value "3" to the resource "cucumber:variable:edge/edge-configuration/max-edge-allowed"
    Given I login as "admin_user"
    And I set the "Content-Type" header to "application/json"
    When I POST "/edge/cucumber" with body:
      """
      {
        "edge_name": "edge_authn"
      }
      """
    Then the HTTP response status code is 201
    And Edge name "edge_authn" data exists in db
    And I clear the "Content-Type" header
    And I log out


  @acceptance
  Scenario: Fetching all authenticators with edge host and Accept-Encoding base64 header return 200 OK
    Given I login as the host associated with Edge "edge_authn"
    And I set the "Accept-Encoding" header to "base64"
    When I successfully GET "/edge/authenticators/cucumber?kind=authn-jwt"
    Then the HTTP response status code is 200
    And the JSON should be:
    """
       {
        "authn-jwt": [
          {
            "audience": null,
            "caCert": "",
            "claimAliases": null,
            "enabled": false,
            "enforcedClaims": null,
            "id": "cucumber:webservice:conjur/authn-jwt/bestAuthenticator",
            "identityPath": null,
            "issuer": null,
            "jwksUri": "",
            "permissions": null,
            "publicKeys": null,
            "tokenAppProperty": null
          },
          {
            "id": "cucumber:webservice:conjur/authn-jwt/myVendor",
            "enabled": true,
            "permissions": [
              {
                "privilege": "authenticate",
                "role": "cucumber:group:conjur/authn-jwt/myVendor/apps"
              },
              {
                "privilege": "read",
                "role": "cucumber:group:conjur/authn-jwt/myVendor/apps"
              }
            ],
            "jwksUri": "aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vb2F1dGgyL3YzL2NlcnRz",
            "publicKeys": null,
            "caCert": "",
            "tokenAppProperty": "YXBwX25hbWU=",
            "identityPath": "ZGF0YS9teXNwYWNlL2p3dC1hcHBz",
            "issuer": "aHR0cHM6Ly9sb2dpbi5leGFtcGxlLmNvbQ==",
            "enforcedClaims":  [
               "Z29vZ2xlL2NsYWlt",
               "YXp1cmUvY2xhaW0=",
               ""
             ],
            "claimAliases":  [
               {
                 "annotationName": "Y2xhaW0=",
                 "claimName": "Z29vZ2xlL2NsYWlt"
               },
               {
                 "annotationName": "",
                 "claimName": ""
               },
               {
                 "annotationName": "bXljbGFpbQ==",
                 "claimName": ""
               },
               {
                 "annotationName": "bXljbGFpbQ==",
                 "claimName": "OmF6dXJlL2NsYWlt"
               },
               {
                 "annotationName": "",
                 "claimName": ""
               }
             ],
            "audience": ""
          },
          {
            "id": "cucumber:webservice:conjur/authn-jwt/withoutPermissions",
            "enabled": false,
            "permissions": null,
            "jwksUri": "",
            "publicKeys": null,
            "caCert": "",
            "tokenAppProperty": null,
            "identityPath": null,
            "issuer": null,
            "enforcedClaims": [],
            "claimAliases": [],
            "audience": null
          }
        ]
      }
    """

  @acceptance
  Scenario: Fetching authenticators with parameters
    Given I login as the host associated with Edge "edge_authn"
    And I set the "Accept-Encoding" header to "base64"
    When I GET "/edge/authenticators/cucumber" with parameters:
    """
    kind: authn-jwt
    limit: 2
    offset: 1
    """
    Then the HTTP response status code is 200
    And the JSON should be:
     """
       {
        "authn-jwt": [
          {
            "id": "cucumber:webservice:conjur/authn-jwt/myVendor",
            "enabled": true,
            "permissions": [
              {
                "privilege": "authenticate",
                "role": "cucumber:group:conjur/authn-jwt/myVendor/apps"
              },
              {
                "privilege": "read",
                "role": "cucumber:group:conjur/authn-jwt/myVendor/apps"
              }
            ],
            "jwksUri": "aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vb2F1dGgyL3YzL2NlcnRz",
            "publicKeys": null,
            "caCert": "",
            "tokenAppProperty": "YXBwX25hbWU=",
            "identityPath": "ZGF0YS9teXNwYWNlL2p3dC1hcHBz",
            "issuer": "aHR0cHM6Ly9sb2dpbi5leGFtcGxlLmNvbQ==",
            "enforcedClaims":  [
               "Z29vZ2xlL2NsYWlt",
               "YXp1cmUvY2xhaW0=",
               ""
             ],
            "claimAliases":  [
               {
                 "annotationName": "Y2xhaW0=",
                 "claimName": "Z29vZ2xlL2NsYWlt"
               },
               {
                 "annotationName": "",
                 "claimName": ""
               },
               {
                 "annotationName": "bXljbGFpbQ==",
                 "claimName": ""
               },
               {
                 "annotationName": "bXljbGFpbQ==",
                 "claimName": "OmF6dXJlL2NsYWlt"
               },
               {
                 "annotationName": "",
                 "claimName": ""
               }
             ],
            "audience": ""
          },
          {
            "id": "cucumber:webservice:conjur/authn-jwt/withoutPermissions",
            "enabled": false,
            "permissions": null,
            "jwksUri": "",
            "publicKeys": null,
            "caCert": "",
            "tokenAppProperty": null,
            "identityPath": null,
            "issuer": null,
            "enforcedClaims": [],
            "claimAliases": [],
            "audience": null
          }
        ]
      }
     """
    When I GET "/edge/authenticators/cucumber" with parameters:
    """
    kind: authn-jwt
    limit: 10
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON at "authn-jwt" should have 3 entries

    When I GET "/edge/authenticators/cucumber" with parameters:
    """
    kind: authn-jwt
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON at "authn-jwt" should have 3 entries
    When I GET "/edge/authenticators/cucumber" with parameters:
    """
    kind: authn-jwt
    offset: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "authn-jwt" should have 1 entries
    When I GET "/edge/authenticators/cucumber" with parameters:
    """
    kind: authn-jwt
    limit: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "authn-jwt" should have 2 entries
    When I GET "/edge/authenticators/cucumber" with parameters:
    """
    kind: authn-jwt
    limit: 5
    """
    Then the HTTP response status code is 200
    And the JSON at "authn-jwt" should have 3 entries
    When I GET "/edge/authenticators/cucumber" with parameters:
    """
    kind: authn-jwt
    limit: 0
    """
    Then the HTTP response status code is 422
    When I GET "/edge/authenticators/cucumber" with parameters:
    """
    kind: authn-jwt
    limit: 2001
    """
    Then the HTTP response status code is 422


  @negative
  Scenario: Fetching authenticators with non edge host return 403 error
    Given I login as "some_user"
    And I set the "Accept-Encoding" header to "base64"
    When I GET "/edge/authenticators/cucumber?kind=authn-jwt"
    Then the HTTP response status code is 403
    Given I am the super-user
    And I set the "Accept-Encoding" header to "base64"
    When I GET "/edge/authenticators/cucumber?kind=authn-jwt"
    Then the HTTP response status code is 403

  @negative
  Scenario: Fetching all authenticators with edge host and without Accept-Encoding base64 header and return 500
    Given I login as the host associated with Edge "edge_authn"
    When I GET "/edge/authenticators/cucumber?kind=authn-jwt"
    Then the HTTP response status code is 500

  @acceptance
  Scenario: Fetching authenticators with invalid kind and return 422
    Given I login as the host associated with Edge "edge_authn"
    And I set the "Accept-Encoding" header to "base64"
    When I GET "/edge/authenticators/cucumber?kind=authn-something"
    Then the HTTP response status code is 422

  @acceptance
  Scenario: Fetching authenticators with empty kind and return 422
    Given I login as the host associated with Edge "edge_authn"
    And I set the "Accept-Encoding" header to "base64"
    When I GET "/edge/authenticators/cucumber?kind="
    Then the HTTP response status code is 422

  @acceptance
  Scenario: Fetching authenticators with no kind and return 422
    Given I login as the host associated with Edge "edge_authn"
    And I set the "Accept-Encoding" header to "base64"
    When I GET "/edge/authenticators/cucumber"
    Then the HTTP response status code is 422

  @acceptance
  Scenario: Fetching authenticators count
    Given I login as the host associated with Edge "edge_authn"
    When I successfully GET "/edge/authenticators/cucumber?kind=authn-jwt&count=true"
    And the JSON should be:
    """
      {
        "count": {
          "authn-jwt": 3
        }
      }
    """

