@authenticators_oidc @skip
Feature: A user can view the various authenticators they can use.

  Background:
    Given the following environment variables are available:
      | context_variable   | environment_variable | default_value |
      | oidc_provider_uri  | OKTA_PROVIDER_URI    |               |

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

    And I set the following conjur variables:
      | variable_id                               | context_variable  | default_value       |
      | conjur/authn-oidc/oidceast/provider-uri   | oidc_provider_uri |                     |
      | conjur/authn-oidc/oidceast/client-id      |                   | foo-bar             |
      | conjur/authn-oidc/oidceast/client-secret  |                   | foo-bar             |
      | conjur/authn-oidc/oidceast/name           |                   | oidceast            |
      | conjur/authn-oidc/oidceast/claim-mapping  |                   | preferred_username  |
      | conjur/authn-oidc/okta/provider-uri       | oidc_provider_uri |                     |
      | conjur/authn-oidc/okta/client-id          |                   | foo-bar             |
      | conjur/authn-oidc/okta/client-secret      |                   | foo-bar             |
      | conjur/authn-oidc/okta/name               |                   | okta                |
      | conjur/authn-oidc/okta/claim-mapping      |                   | preferred_username  |

    Then the list of authenticators contains the service-id "oidceast"
    Then the list of authenticators contains the service-id "okta"
