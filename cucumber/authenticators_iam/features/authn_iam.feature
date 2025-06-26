@authenticators_iam
Feature: IAM Authenticator

  In this feature we define a IAM authenticator in policy and perform authentication

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-iam/prod
      body:
      - !webservice

      - !group apps
      - !variable optional-signed-headers

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I have host "188945769008/dev_limited_user"
    And I grant group "conjur/authn-iam/prod/apps" to host "188945769008/dev_limited_user"
    And I add the secret value "content-type;date" to the resource "cucumber:variable:conjur/authn-iam/prod/optional-signed-headers"

  @smoke
  Scenario: Hosts can authenticate with IAM authenticator and fetch secret
    Given I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "188945769008/dev_limited_user" to "execute" it
    And I obtain a valid IAM identity token
    And I save my place in the log file
    When I authenticate with authn-iam using a valid identity token for "host/188945769008/dev_limited_user"
    Then host "188945769008/dev_limited_user" has been authorized by Conjur
    And I can GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:188945769008/dev_limited_user successfully authenticated with authenticator authn-iam service cucumber:webservice:conjur/authn-iam/prod
    """
