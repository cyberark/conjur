@authenticators_status
Feature: Authenticator status check

  Conjur supports a Status check where users can get immediate feedback
  on authenticator configuration.

  The Status check for OIDC V2 includes checking that all variables are
  set, that the scope/response-type/claim-mapping variables have valid
  values based on the OIDC spec, the given provider-uri is reachable, and
  that the values redirect to a valid OIDC login page (e.g. that the
  client ID/redirect uri/etc are all valid).

  Background:
    Given I load a policy:
    """
      - !policy
        id: conjur/authn-oidc/keycloak_status
        body:
          - !webservice
          - !webservice status

          - !variable name
          - !variable provider-uri

          - !variable response-type

          - !variable client-id

          - !variable client-secret

          - !variable claim-mapping

          - !variable state

          - !variable nonce

          - !variable redirect-uri

          - !variable scope

          - !variable required-request-parameters

          - !group users

          - !permit
            role: !group users
            privilege: [ read, authenticate ]
            resource: !webservice

      - !user alice

      - !grant
        role: !group conjur/authn-oidc/keycloak_status/users
        member: !user alice
    """
    And I am the super-user

  @negative @acceptance
  Scenario: Status of OIDC V2 authenticator with missing variable value
    When I GET "/authn-oidc/keycloak_status/cucumber/status"
    Then the HTTP response status code is 500
    And the JSON should be:
    """
    {
      "status": "error",
      "error": "#<Errors::Conjur::RequiredResourceMissing: CONJ00036E Missing required resource: cucumber:variable:conjur/authn-oidc/keycloak_status/id-token-user-property>"
    }
    """


  @smoke
  Scenario: Status of correctly setup OIDC V2 authenticator
    Given I successfully set OIDC V2 variables with service id: "keycloak_status"
    When I GET "/authn-oidc/keycloak_status/cucumber/status"
    Then the HTTP response status code is 200

  @negative @acceptance
  Scenario: Status of OIDC V2 authenticator with invalid client ID
    Given I successfully set OIDC V2 variables with service id: "keycloak_status"
    And I POST "/secrets/cucumber/variable/conjur%2fauthn-oidc%2fkeycloak_status%2fclient-id" with body:
    """
    bad-id
    """
    When I GET "/authn-oidc/keycloak_status/cucumber/status"
    Then the HTTP response status code is 500
    And the JSON should be:
    """
    {
      "status": "error",
      "error": "#<Errors::Authentication::AuthnOidc::InvalidProviderConfig: CONJ00130E The OIDC provider variable values are misconfigured>"
    }
    """

  @negative @acceptance
  Scenario: Status of OIDC V2 authenticator with invalid provider URI
    Given I successfully set OIDC V2 variables with service id: "keycloak_status"
    And I POST "/secrets/cucumber/variable/conjur%2fauthn-oidc%2fkeycloak_status%2fprovider-uri" with body:
    """
    http://aliksjfrglkasghlarhjasdfjkalkjsfgrh.com
    """
    When I GET "/authn-oidc/keycloak_status/cucumber/status"
    Then the HTTP response status code is 500
    And the JSON should be:
    """
    {
      "status": "error",
      "error": "#<Errors::Authentication::OAuth::ProviderDiscoveryFailed: CONJ00011E Failed to discover Identity Provider (Provider URI: 'http://aliksjfrglkasghlarhjasdfjkalkjsfgrh.com'). Reason: '#<OpenIDConnect::Discovery::DiscoveryFailed: getaddrinfo: Name or service not known (aliksjfrglkasghlarhjasdfjkalkjsfgrh.com:443)>'>"
    }
    """
