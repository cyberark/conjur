Feature: Azure Authenticator - Hosts can authenticate with Azure authenticator

  In this feature we define an Azure authenticator in policy, define different
  hosts and perform authentication with Conjur. In successful scenarios we will
  also define a variable and permit the host to execute it, to verify not
  only that the host can authenticate with the Azure Authenticator, but that
  it can retrieve a secret using the Conjur access token.

  Background:
    Given a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !variable
        id: provider-uri

      - !group
        id: apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I am the super-user
    And I successfully set Azure variables
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"
    And I have a "variable" resource called "test-variable"
    And I permit host "test-app" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"

  Scenario: Hosts can authenticate with Azure authenticator and fetch secret
    Given I fetch an Azure access token from inside machine
    When I authenticate via Azure with token as host "test-app"
    Then host "test-app" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user

  Scenario: A valid provider-uri without trailing slash works
    Given I fetch an Azure access token from inside machine
    When I successfully set Azure provider-uri variable without trailing slash
    And I authenticate via Azure with token as host "test-app"
    Then host "test-app" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user