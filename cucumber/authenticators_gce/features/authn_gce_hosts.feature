Feature: GCP Authenticator - Test hosts can authentication scenarios

  In this feature we define GCE authenticator in policy, test with different
  host configurations and perform authentication with Conjur.

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

  Scenario: Non-existing host is denied
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/host/test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """

