@authenticators_gcp
Feature: GCP Authenticator created via API

  Background:
    Given I load a policy:
    """
    - !policy conjur/authn-gcp
    """
    And I successfully initialize the GCP authenticator via the authenticators API
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
