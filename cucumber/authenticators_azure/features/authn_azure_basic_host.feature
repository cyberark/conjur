@authenticators_azure
Feature: Azure Authenticator - Hosts can authenticate with Azure authenticator

  In this feature we define an Azure authenticator in policy and perform authentication
  with Conjur, using a host with subscription-id & resource-group annotations.
  In successful scenarios we will also define a variable and permit the host to
  execute it, to verify not only that the host can authenticate with the Azure
  Authenticator, but that it can retrieve a secret using the Conjur access token.

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !variable
        id: provider-uri

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I am the super-user
    And I successfully set Azure provider-uri variable with the correct values
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"

  @smoke
  Scenario: Hosts can authenticate with Azure authenticator and fetch secret
    Given I have a "variable" resource called "test-variable"
    And I permit host "test-app" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the audit log file
    When I authenticate via Azure with token as host "test-app"
    Then host "test-app" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-azure service cucumber:webservice:conjur/authn-azure/prod
    """

  @acceptance
  Scenario: A valid provider-uri without trailing slash works
    Given I have a "variable" resource called "test-variable"
    And I permit host "test-app" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I fetch a non-assigned-identity Azure access token from inside machine
    When I successfully set Azure provider-uri variable without trailing slash
    And I authenticate via Azure with token as host "test-app"
    Then host "test-app" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user

  @acceptance
  Scenario: Changing provider-uri dynamically reflects on the ID Provider endpoint
    Given I fetch a non-assigned-identity Azure access token from inside machine
    And I authenticate via Azure with token as host "test-app"
    And host "test-app" has been authorized by Conjur
    # Update provider uri to a different hostname and verify `provider-uri` has changed
    When I add the secret value "https://different-provider:8443" to the resource "cucumber:variable:conjur/authn-azure/prod/provider-uri"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    And I authenticate via Azure with token as host "test-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00007D Working with Identity Provider https://different-provider:8443
    """
    # Check recovery to a valid provider uri
    When I successfully set Azure provider-uri variable with the correct values
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I authenticate via Azure with token as host "test-app"
    And host "test-app" has been authorized by Conjur

  @negative @acceptance
  Scenario: Missing Azure access token is a bad request
    Given I save my place in the log file
    When I authenticate via Azure with no token as host "test-app"
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """

  @negative @acceptance
  Scenario: Empty Azure access token is a bad request
    Given I save my place in the log file
    When I authenticate via Azure with empty token as host "test-app"
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """
