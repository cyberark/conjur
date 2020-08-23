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
    When I authenticate with authn-gce using valid token and existing account
    Then host "test-app" has been authorized by Conjur
    And I can GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app successfully authenticated with authenticator authn-gce service cucumber:webservice:conjur/authn-gce
    """

  Scenario: Host can authenticate with only project-id annotation set
    Given I have host "test-app-project-id-only"
    And I grant group "conjur/authn-gce/apps" to host "test-app-project-id-only"
    And I set "authn-gce/project-id" annotation to host "test-app-project-id-only"
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/host/test-app-project-id-only"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then host "test-app-project-id-only" has been authorized by Conjur
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app-project-id-only successfully authenticated with authenticator authn-gce service cucumber:webservice:conjur/authn-gce
    """

  Scenario: Host can authenticate with only service-account-id annotation set
    Given I have host "test-app-sa-id-only"
    And I grant group "conjur/authn-gce/apps" to host "test-app-sa-id-only"
    And I set "authn-gce/service-account-id" annotation to host "test-app-sa-id-only"
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/host/test-app-sa-id-only"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then host "test-app-sa-id-only" has been authorized by Conjur
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app-sa-id-only successfully authenticated with authenticator authn-gce service cucumber:webservice:conjur/authn-gce
    """

  Scenario: Host can authenticate with only service-account-email annotation set
    Given I have host "test-app-sa-email-only"
    And I grant group "conjur/authn-gce/apps" to host "test-app-sa-email-only"
    And I set "authn-gce/service-account-email" annotation to host "test-app-sa-email-only"
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/host/test-app-sa-email-only"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then host "test-app-sa-email-only" has been authorized by Conjur
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app-sa-email-only successfully authenticated with authenticator authn-gce service cucumber:webservice:conjur/authn-gce
    """

  Scenario: Host can authenticate with only instance-name annotation set
    Given I have host "test-app-instance-name"
    And I grant group "conjur/authn-gce/apps" to host "test-app-instance-name"
    And I set "authn-gce/instance-name" annotation to host "test-app-instance-name"
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/host/test-app-instance-name"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then host "test-app-instance-name" has been authorized by Conjur
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:test-app-instance-name successfully authenticated with authenticator authn-gce service cucumber:webservice:conjur/authn-gce
    """

  Scenario: Non-existing account in request is denied
    Given I obtain a GCE identity token in full format with audience claim value: "conjur/non-existing/host/test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and non-existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00008E Account '.*' is not defined in Conjur
    """
