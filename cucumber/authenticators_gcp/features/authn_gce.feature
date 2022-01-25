@authenticators_gcp
Feature: GCP Authenticator - GCE flow, hosts can authenticate with GCP authenticator

  In this feature we define a GCP authenticator in policy and perform authentication
  with Conjur.
  In successful scenarios we will also define a variable and permit the host to
  execute it, to verify not only that the host can authenticate with the GCP
  Authenticator, but that it can retrieve a secret using the Conjur access token.

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
      body:
      - !webservice

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I am the super-user
    And I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"

  @smoke
  Scenario: Hosts can authenticate with GCP authenticator and fetch secret
    Given I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "test-app" to "execute" it
    And I set all valid GCE annotations to host "test-app"
    And I obtain a valid GCE identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCE token and existing account
    Then host "test-app" has been authorized by Conjur
    And I can GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gcp service cucumber:webservice:conjur/authn-gcp
    """

  @acceptance
  Scenario: Host can authenticate with only project-id annotation set
    Given I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I remove all annotations from host "test-app"
    And I set "authn-gcp/project-id" GCE annotation to host "test-app"
    And I obtain a valid GCE identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCE token and existing account
    Then host "test-app" has been authorized by Conjur
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gcp service cucumber:webservice:conjur/authn-gcp
    """

  @acceptance
  Scenario: Host can authenticate with only service-account-id annotation set
    Given I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-id" GCE annotation to host "test-app"
    And I obtain a valid GCE identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCE token and existing account
    Then host "test-app" has been authorized by Conjur
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gcp service cucumber:webservice:conjur/authn-gcp
    """

  @acceptance
  Scenario: Host can authenticate with only service-account-email annotation set
    Given I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-email" GCE annotation to host "test-app"
    And I obtain a valid GCE identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCE token and existing account
    Then host "test-app" has been authorized by Conjur
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gcp service cucumber:webservice:conjur/authn-gcp
    """

  @acceptance
  Scenario: Host can not authenticate with only instance-name annotation set
    Given I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I remove all annotations from host "test-app"
    And I set "authn-gcp/instance-name" GCE annotation to host "test-app"
    And I obtain a valid GCE identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCE token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00069E Role must have at least one of the following constraints: ["project-id", "service-account-id", "service-account-email"]
    """

  @negative @acceptance
  Scenario: Non-existing account in token audience claim is denied
    Given I obtain a non_existing_account GCE identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using obtained GCE token and existing account
    Then it is unauthorized
    And The following matches the log after my savepoint:
    """
    CONJ00070E 'audience' token claim .* is invalid. The account in the audience .* does not match the account in the URL request .*
    """
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:USERNAME_MISSING failed to authenticate with authenticator authn-gcp service
    """

  @negative @acceptance
  Scenario: Non-existing account in URL request is denied
    Given I save my place in the log file
    When I authenticate with authn-gcp using obtained GCE token and non-existing account
    Then it is unauthorized
    And The following matches the log after my savepoint:
    """
    CONJ00008E Account '.*' is not defined in Conjur
    """
    And The following appears in the audit log after my savepoint:
    """
    non-existing:user:USERNAME_MISSING failed to authenticate with authenticator authn-gcp service
    """

  @acceptance
  Scenario: Authenticate using token in standard format and host with only service-account-id annotation set
    Given I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-id" GCE annotation to host "test-app"
    And I save my place in the log file
    And I obtain a standard_format GCE identity token
    And I authenticate with authn-gcp using obtained GCE token and existing account
    Then host "test-app" has been authorized by Conjur
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gcp service cucumber:webservice:conjur/authn-gcp
    """

  @negative @acceptance
  Scenario: Requests with an existing user ID in URL is responded with not found
    Given I save my place in the log file
    When I authenticate with authn-gcp using no token and user id "host%2Ftest-app" in the request
    Then it is not found
    And The following appears in the log after my savepoint:
    """
    ActionController::RoutingError (No route matches [POST] "/authn-gcp/cucumber/host%2Ftest-app/authenticate")
    """

  @negative @acceptance
  Scenario: Requests with a non-existing user ID in URL is responded with not found
    Given I save my place in the log file
    When I authenticate with authn-gcp using no token and user id "host%2Fnon-existing" in the request
    Then it is not found
    And The following appears in the log after my savepoint:
    """
    ActionController::RoutingError (No route matches [POST] "/authn-gcp/cucumber/host%2Fnon-existing/authenticate")
    """
