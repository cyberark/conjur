@authenticators_azure
Feature: Azure Authenticator - Different Hosts can authenticate with Azure authenticator

  In this feature we define an Azure authenticator in policy, define different
  hosts and perform authentication with Conjur.

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

  @smoke
  Scenario: Host with system-assigned-identity annotation is authorized
    And I have host "system-assigned-identity-app"
    And I set subscription-id annotation to host "system-assigned-identity-app"
    And I set resource-group annotation to host "system-assigned-identity-app"
    And I set system-assigned-identity annotation to host "system-assigned-identity-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "system-assigned-identity-app"
    And I fetch a system-assigned-identity Azure access token from inside machine
    When I authenticate via Azure with token as host "system-assigned-identity-app"
    Then host "system-assigned-identity-app" has been authorized by Conjur

  @negative @acceptance
  Scenario: Host without resource-group annotation is denied
    And I have host "no-resource-group-app"
    And I set subscription-id annotation to host "no-resource-group-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "no-resource-group-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "no-resource-group-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Constraints::RoleMissingConstraints: CONJ00057E Role does not have the required constraints: '["resource-group"]'
    """

  @negative @acceptance
  Scenario: Host without subscription-id annotation is denied
    And I have host "no-subscription-id-app"
    And I set resource-group annotation to host "no-subscription-id-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "no-subscription-id-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "no-subscription-id-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Constraints::RoleMissingConstraints: CONJ00057E Role does not have the required constraints: '["subscription-id"]'
    """

  @negative @acceptance
  Scenario: Host without any Azure annotation is denied
    And I have host "no-azure-annotations-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "no-azure-annotations-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "no-azure-annotations-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Constraints::RoleMissingConstraints
    """

  @negative @acceptance
  Scenario: Host with both identity Azure annotations is denied
    And I have host "illegal-combination-app"
    And I set resource-group annotation to host "illegal-combination-app"
    And I set subscription-id annotation to host "illegal-combination-app"
    And I set system-assigned-identity annotation to host "illegal-combination-app"
    And I set user-assigned-identity annotation to host "illegal-combination-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "illegal-combination-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "illegal-combination-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Constraints::IllegalConstraintCombinations
    """

  @negative @acceptance
  Scenario: Host with incorrect subscription-id Azure annotation is denied
    And I have host "incorrect-subscription-id-app"
    And I set resource-group annotation to host "incorrect-subscription-id-app"
    And I set subscription-id annotation with incorrect value to host "incorrect-subscription-id-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "incorrect-subscription-id-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "incorrect-subscription-id-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions
    """

  @negative @acceptance
  Scenario: Host with incorrect resource-group Azure annotation is denied
    And I have host "incorrect-resource-group-app"
    And I set subscription-id annotation to host "incorrect-resource-group-app"
    And I set resource-group annotation with incorrect value to host "incorrect-resource-group-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "incorrect-resource-group-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "incorrect-resource-group-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions
    """

  @negative @acceptance
  Scenario: Host with incorrect user-assigned-identity annotation is denied
    And I have host "incorrect-user-assigned-identity-app"
    And I set subscription-id annotation to host "incorrect-user-assigned-identity-app"
    And I set resource-group annotation to host "incorrect-user-assigned-identity-app"
    And I set user-assigned-identity annotation with incorrect value to host "incorrect-user-assigned-identity-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "incorrect-user-assigned-identity-app"
    And I fetch a user-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "incorrect-user-assigned-identity-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions
    """

  @negative @acceptance
  Scenario: Host with incorrect system-assigned-identity annotation is denied
    And I have host "incorrect-system-assigned-identity-app"
    And I set subscription-id annotation to host "incorrect-system-assigned-identity-app"
    And I set resource-group annotation to host "incorrect-system-assigned-identity-app"
    And I set system-assigned-identity annotation with incorrect value to host "incorrect-system-assigned-identity-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "incorrect-system-assigned-identity-app"
    And I fetch a system-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "incorrect-system-assigned-identity-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions
    """

  @negative @acceptance
  Scenario: Non-existing host is denied
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "non-existing-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:non-existing-app failed to authenticate with authenticator authn-azure service cucumber:webservice:conjur/authn-azure/prod
    """

  @negative @acceptance
  Scenario: Host that is not in the permitted group is denied
    And I have host "non-permitted-app"
    And I set Azure annotations to host "non-permitted-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "non-permitted-app"
    Then it is forbidden
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource
    """

  # This test runs a failing authentication request that is already
  # tested in another scenario (Host without resource-group annotation is denied).
  # We run it again here to verify that we write a message to the audit log
  @acceptance
  Scenario: Authentication failure is written to the audit log
    And I have host "no-resource-group-app"
    And I set subscription-id annotation to host "no-resource-group-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "no-resource-group-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the audit log file
    When I authenticate via Azure with token as host "no-resource-group-app"
    Then it is unauthorized
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:no-resource-group-app failed to authenticate with authenticator authn-azure service cucumber:webservice:conjur/authn-azure/prod
    """
