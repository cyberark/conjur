@authenticators_azure
Feature: Azure Authenticator created via API

  Background:
    When I load a policy:
    """
    - !policy conjur/authn-azure
    """
    Given I successfully initialize an Azure authenticator named "prod" via the authenticators API

  @smoke
  Scenario: Host with user-assigned-identity annotation is authorized
    And I have host "user-assigned-identity-app"
    And I set subscription-id annotation to host "user-assigned-identity-app"
    And I set resource-group annotation to host "user-assigned-identity-app"
    And I set user-assigned-identity annotation to host "user-assigned-identity-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "user-assigned-identity-app"
    And I fetch a user-assigned-identity Azure access token from inside machine
    When I authenticate via Azure with token as host "user-assigned-identity-app"
    Then host "user-assigned-identity-app" has been authorized by Conjur
