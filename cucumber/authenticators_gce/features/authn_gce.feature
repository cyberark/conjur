Feature: GCE Authenticator - Hosts can authenticate with GCE authenticator

  In this feature we define a GCE authenticator in policy and perform authentication
  with Conjur.
  In successful scenarios we will also define a variable and permit the host to
  execute it, to verify not only that the host can authenticate with the GCE
  Authenticator, but that it can retrieve a secret using the Conjur access token.

  Background:
    Given a policy:
    """
    - !policy
      id: conjur/authn-gce
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
    And I grant group "conjur/authn-gce/apps" to host "test-app"

  Scenario: Hosts can authenticate with GCE authenticator and fetch secret
    Given I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "test-app" to "execute" it
    And I set all valid GCE annotations to host "test-app"
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/host/test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using token and existing account
    Then host "test-app" has been authorized by Conjur
    And I can GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gce service cucumber:webservice:conjur/authn-gce
    """

  Scenario: Missing GCE access token is a bad request
    Given I save my place in the log file
    When I authenticate with authn-gce using no token and existing account
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """


  Scenario: Empty GCE access token is a bad request
    Given I save my place in the log file
    When I authenticate with authn-gce using empty token and existing account
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::RequestBody::MissingRequestParam
    """

  Scenario: Non-existing account in request is denied
    Given I obtain a GCE identity token in full format with audience claim value: "conjur/non-existing/host/test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using token and non existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::AccountNotDefined
    """
