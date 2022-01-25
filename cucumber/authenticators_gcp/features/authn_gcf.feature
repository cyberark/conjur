@authenticators_gcp
Feature: GCP Authenticator - GCF flow, hosts can authenticate with GCP authenticator

  In this feature we define a GCP authenticator in policy and perform authentication
  with Conjur using Google tokens created in a Google function.
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
    And I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"

  @smoke
  Scenario: Hosts can authenticate with GCP authenticator and fetch secret
    Given I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "test-app" to "execute" it
    And I remove all annotations from host "test-app"
    And I set all valid GCF annotations to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then host "test-app" has been authorized by Conjur
    And I can GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gcp service cucumber:webservice:conjur/authn-gcp
    """

  @acceptance
  Scenario: Hosts can authenticate with GCP authenticator using service-account-id annotation only and fetch secret
    Given I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "test-app" to "execute" it
    And I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-id" GCF annotations to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then host "test-app" has been authorized by Conjur
    And I can GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gcp service cucumber:webservice:conjur/authn-gcp
    """

  @acceptance
  Scenario: Hosts can authenticate with GCP authenticator using service-account-email annotation only and fetch secret
    Given I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "test-app" to "execute" it
    And I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-email" GCF annotations to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then host "test-app" has been authorized by Conjur
    And I can GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gcp service cucumber:webservice:conjur/authn-gcp
    """
