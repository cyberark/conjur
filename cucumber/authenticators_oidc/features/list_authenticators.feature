@authenticators_oidc
Feature: A user can view the various authenticators they can use.

  @smoke
  Scenario: List readable authenticators

    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/oidceast
      body:
      - !webservice
      - !webservice status
      - !variable provider-uri
      - !variable client-id
      - !variable client-secret
      - !variable name
      - !variable claim-mapping
      - !variable nonce
      - !variable state
      - !group
        id: authenticatable
        annotations:
          description: Users who can authenticate using this authenticator
      - !permit
        role: !group authenticatable
        privilege: [ read, authenticate ]
        resource: !webservice
    """

    And I extend the policy with:
   """
    - !policy
      id: conjur/authn-oidc/okta
      body:
      - !webservice
      - !webservice status
      - !variable provider-uri
      - !variable name
      - !variable client-id
      - !variable client-secret
      - !variable claim-mapping
      - !variable nonce
      - !variable state
      - !group
        id: authenticatable
        annotations:
          description: Users who can authenticate using this authenticator
      - !permit
        role: !group authenticatable
        privilege: [ read, authenticate ]
        resource: !webservice
    """

    And I extend the policy with:
    """
    - !group secrets-fetchers
    - !group cant-authenticate
    - !user
      id: alice
      annotations:
       authn-oidc/oidceast: alice.somebody@cyberark.com
    - !user
      id: bob
      annotations:
       authn-oidc/okta: bob.somebody@cyberark.com
    - !grant
      role: !group cant-authenticate
      member: !user bob
    - !grant
      role: !group secrets-fetchers
      member: !user alice
    - !grant
      role: !group conjur/authn-oidc/oidceast/authenticatable
      member: !group secrets-fetchers
    """
    Then I can add a provider-url to variable resource "conjur/authn-oidc/oidceast/provider-uri"
    Then I can add a secret to variable resource "conjur/authn-oidc/oidceast/client-id"
    Then I can add a secret to variable resource "conjur/authn-oidc/oidceast/client-secret"
    Then I can add the secret "oidceast" resource "conjur/authn-oidc/oidceast/name"
    Then I can add a secret to variable resource "conjur/authn-oidc/oidceast/claim-mapping"
    Then I can add a secret to variable resource "conjur/authn-oidc/oidceast/nonce"
    Then I can add a secret to variable resource "conjur/authn-oidc/oidceast/state"
    Then I can add a provider-url to variable resource "conjur/authn-oidc/okta/provider-uri"
    Then I can add a secret to variable resource "conjur/authn-oidc/okta/client-id"
    Then I can add the secret "okta" resource "conjur/authn-oidc/okta/name"
    Then I can add a secret to variable resource "conjur/authn-oidc/okta/client-secret"
    Then I can add a secret to variable resource "conjur/authn-oidc/okta/claim-mapping"
    Then I can add a secret to variable resource "conjur/authn-oidc/okta/nonce"
    Then I can add a secret to variable resource "conjur/authn-oidc/okta/state"
    When I log in as user "admin"
    Then the list of authenticators contains the service-id "oidceast"
    Then the list of authenticators contains the service-id "okta"