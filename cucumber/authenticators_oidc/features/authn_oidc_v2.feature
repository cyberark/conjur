@authenticators_oidc
Feature: OIDC Authenticator V2 - Users can authenticate with OIDC authenticator

  In this feature we define an OIDC authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the user to
  execute it, to verify not only that the user can authenticate with the OIDC
  Authenticator, but that it can retrieve a secret using the Conjur access token.

  Background:
    Given I load a policy:
    """
      - !policy
        id: conjur/authn-oidc/keycloak2
        body:
          - !webservice
            annotations:
              description: Authentication service for Keycloak, based on Open ID Connect.
          - !variable name
          - !variable provider-uri
          - !variable response-type
          - !variable client-id
          - !variable client-secret
          - !variable claim-mapping
          - !variable redirect-uri
          - !variable provider-scope

          - !group users

          - !permit
            role: !group users
            privilege: [ read, authenticate ]
            resource: !webservice

      - !user alice

      - !grant
        role: !group conjur/authn-oidc/keycloak2/users
        member: !user alice
    """
    And I am the super-user
    And I set conjur variables
      | variable_id                                 | value                                     |
      | conjur/authn-oidc/keycloak2/provider-uri    | https://keycloak:8443/auth/realms/master  |
      | conjur/authn-oidc/keycloak2/client-id       | conjurClient                              |
      | conjur/authn-oidc/keycloak2/client-secret   | 1234                                      |
      | conjur/authn-oidc/keycloak2/claim-mapping   | preferred_username                        |
      | conjur/authn-oidc/keycloak2/redirect-uri    | http://conjur:3000/authn-oidc/keycloak2/cucumber/authenticate |

  @smoke
  Scenario: A valid code to get Conjur access token
    # We want to verify the returned access token is valid for retrieving a secret
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a code for username "alice" and password "alice"
    And I save my place in the audit log file
    When I authenticate via OIDC V2 with code
    Then user "alice" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak2
    """

  @smoke
  Scenario: A valid code to get Conjur access token and OIDC refresh token
    Given I enable OIDC V2 refresh token flows for "keycloak2"
    And I fetch a code for username "alice" and password "alice"
    When I authenticate via OIDC V2 with code
    Then user "alice" has been authorized by Conjur
    And The authentication response includes header "X-OIDC-Refresh-Token"

  @smoke
  Scenario: OIDC V2 logout endpoint kicks off RP-Initiated logout
    Given I enable OIDC V2 refresh token flows for "keycloak2"
    And I fetch a code for username "alice" and password "alice"
    And I authenticate via OIDC V2 with code
    And The authentication response includes header "X-OIDC-Refresh-Token"
    When I logout from the OIDC V2 authenticator "keycloak2" with state "rand-state" and redirect URI "https://conjur.org/redirect"
    Then The response includes the OIDC provider's logout URI

  @smoke
  Scenario: A valid refresh token to get Conjur access token and OIDC refresh token
    Given I enable OIDC V2 refresh token flows for "keycloak2"
    And I fetch a code for username "alice" and password "alice"
    And I authenticate via OIDC V2 with code
    And The authentication response includes header "X-OIDC-Refresh-Token"
    When I store the current access token
    And I authenticate via OIDC V2 with refresh token
    Then user "alice" has been authorized by Conjur
    And a new access token was issued

  @smoke
  Scenario: A valid code with email as claim mapping
    Given I extend the policy with:
    """
    - !user alice@conjur.net
    - !grant
      role: !group conjur/authn-oidc/keycloak2/users
      member: !user alice@conjur.net
    """
    When I add the secret value "email" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/claim-mapping"
    And I fetch a code for username "alice@conjur.net" and password "alice"
    And I authenticate via OIDC V2 with code
    Then user "alice@conjur.net" has been authorized by Conjur

  @smoke
  Scenario: Adding a group to keycloak2/users group permits users to authenticate
    Given I extend the policy with:
    """
    - !user
      id: bob.somebody
    - !group more-users
    - !grant
      role: !group more-users
      member: !user bob.somebody
    - !grant
      role: !group conjur/authn-oidc/keycloak2/users
      member: !group more-users
    """
    And I fetch a code for username "bob@conjur.net" and password "bob"
    When I authenticate via OIDC V2 with code
    Then user "bob.somebody" has been authorized by Conjur

  @negative @acceptance
  Scenario: Non-existing username in claim mapping is denied
    Given I fetch a code for username "not_in_conjur" and password "not_in_conjur"
    And I save my place in the log file
    When I authenticate via OIDC V2 with code
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """
#    And The following appears in the audit log after my savepoint:
#    """
#     failed to authenticate with authenticator authn-oidc service cucumber:webservice:conjur/authn-oidc/keycloak2
#    """

  @negative @acceptance
  Scenario: User that is not permitted to webservice in claim mapping is denied
    Given I extend the policy with:
    """
    - !user
      id: bob@conjur.net
    """
    And I fetch a code for username "bob@conjur.net" and password "bob"
    And I save my place in the log file
    When I authenticate via OIDC V2 with code
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """

  @negative @acceptance
  Scenario: Code without value of variable claim mapping is denied
    When I add the secret value "non_existing_field" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/claim-mapping"
    And I fetch a code for username "alice@conjur.net" and password "alice"
    And I save my place in the log file
    When I authenticate via OIDC V2 with code
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
    """

  @negative @acceptance
  Scenario: Adding a group to keycloak2/users group permits users to authenticate
    Given I extend the policy with:
    """
    - !user
      id: bob
      annotations:
        authn-oidc/identity: bob.somebody
    - !group more-users
    - !grant
      role: !group more-users
      member: !user bob
    - !grant
      role: !group conjur/authn-oidc/keycloak2/users
      member: !group more-users
    """

  @negative @acceptance
  Scenario: Missing code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice"
    When I authenticate via OIDC V2 with no code in the request
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """
#    And The following appears in the audit log after my savepoint:
#    """
#    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
#    """

  @negative @acceptance
  Scenario: Empty code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice"
    When I authenticate via OIDC V2 with code ""
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """
#    And The following appears in the audit log after my savepoint:
#    """
#    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-oidc service
#    """

  @negative @acceptance
  Scenario: Invalid code is a bad request
    Given I save my place in the log file
    And I fetch a code for username "alice@conjur.net" and password "alice"
    When I authenticate via OIDC V2 with code "bad-code"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Rack::OAuth2::Client::Error
    """

  @negative @acceptance
  Scenario: Bad OIDC provider credentials
    Given I save my place in the log file
    And I fetch a code for username "alice" and password "notalice"
    When I authenticate via OIDC V2 with code
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """

  @negative @acceptance
  Scenario: Non-Existent authenticator is not found
    Given I save my place in the log file
    And I fetch a code for username "alice" and password "alice"
    When I authenticate via OIDC V2 with code and service-id "non-exist"
    Then it is not found
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequestedResourceNotFound: CONJ00123E Resource
    """


  # This test throws an error because the provider URI is invalid.
  # TODO - add a test to verify URI valididity of provider uri
  # TODO - throw a valid exception when the provider fails to load an OIDC
  #         endpoint during the service discover (which occurs when rendering the
  #         provider list)
  #
  # Does this test actually make sense?
  # @smoke
  # Scenario: provider-uri dynamic change
  #   And I fetch a code for username "alice" and password "alice"
  #   And I authenticate via OIDC V2 with code
  #   And user "alice" has been authorized by Conjur
  #   # Update provider uri to a different hostname and verify `provider-uri` has changed
  #   When I add the secret value "https://different-provider:8443" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/provider-uri"
  #   And I authenticate via OIDC V2 with code
  #   Then it is unauthorized
  #   # Check recovery to a valid provider uri
  #   # When I successfully set OIDC V2 variables for "keycloak2"
  #   And I fetch a code for username "alice" and password "alice"
  #   And I authenticate via OIDC V2 with code
  #   Then user "alice" has been authorized by Conjur

  @negative @acceptance
  Scenario: Unauthenticated is raised in case of an invalid OIDC Provider hostname
    Given I fetch a code for username "alice" and password "alice"
    And I authenticate via OIDC V2 with code
    And user "alice" has been authorized by Conjur
    # Update provider uri to reachable but invalid hostname
    When I add the secret value "http://127.0.0.1.com/" to the resource "cucumber:variable:conjur/authn-oidc/keycloak2/provider-uri"
    And I save my place in the log file
    And I authenticate via OIDC V2 with code
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::OAuth::ProviderDiscoveryFailed
    """
