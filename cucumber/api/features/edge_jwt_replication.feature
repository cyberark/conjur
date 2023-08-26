@api
Feature: Replicate jwt authenticators from edge endpoint

  Background:
    Given I create a new user "some_user"
    And I create a new user "admin_user"
    And I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: edge
      body:
        - !group edge-hosts
        - !policy
            id: edge-abcd1234567890
            body:
            - !host
              id: edge-host-abcd1234567890
              annotations:
                authn/api-key: true
        - !policy
            id: edge-configuration
            body:
              - &edge-variables
                - !variable max-edge-allowed
    - !grant
      role: !group edge/edge-hosts
      members:
        - !host edge/edge-abcd1234567890/edge-host-abcd1234567890

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
    """
    And I add the secret value "https://www.googleapis.com/oauth2/v3/certs" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/jwks-uri"
    And I add the secret value "app_name" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/token-app-property"
    And I add the secret value "data/myspace/jwt-apps" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/identity-path"
    And I add the secret value "https://login.example.com" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/issuer"
    And I add the secret value "additional_data/group_id" to the resource "cucumber:variable:conjur/authn-jwt/myVendor/enforced-claims"
    And I log out

  @acceptance
  Scenario: Fetching all authenticators with edge host and Accept-Encoding base64 header return 200 OK
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    And I set the "Accept-Encoding" header to "base64"
    When I successfully GET "/edge/authenticators/cucumber?kind=authn-jwt"
    Then the HTTP response status code is 200

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
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/authenticators/cucumber?kind=authn-jwt"
    Then the HTTP response status code is 500

    # todo : see why it is not returned 422 status
  @acceptance
  Scenario: Fetching authenticators with invalid kind and return 422
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    And I set the "Accept-Encoding" header to "base64"
    When I successfully GET "/edge/authenticators/cucumber?kind=authn-something"
    Then the HTTP response status code is 422

  @acceptance
  Scenario: Fetching authenticators count
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I successfully GET "/edge/hosts/cucumber?count=true"
    And the JSON should be:
    """
      {
        "count": {
          "authn-jwt": 2
        }
      }
    """
