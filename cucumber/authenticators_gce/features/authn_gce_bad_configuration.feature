Feature: GCE Authenticator - Test Malformed Configuration

  In this feature we define a GCE authenticator with a malformed configuration.
  Each test will verify a failure of the authentication request in such a case
  and log the relevant error for the user to re-configure the authenticator
  properly.

  Scenario: Webservice missing in policy is denied
    Given a policy:
    """
    - !policy
      id: conjur/authn-gce
      body:

      - !group apps
    """
    And I am the super-user
    And I have host "test-app"
    And I set all valid GCE annotations to host "test-app"
    And I grant group "conjur/authn-gce/apps" to host "test-app"
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/host/test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::WebserviceNotFound
    """

  Scenario: Webservice with read and no authenticate permission in policy is denied
    Given a policy:
    """
    - !policy
      id: conjur/authn-gce
      body:
      - !webservice

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read ]
        resource: !webservice
    """
    And I am the super-user
    And I have host "test-app"
    And I set all valid GCE annotations to host "test-app"
    And I grant group "conjur/authn-gce/apps" to host "test-app"
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/host/test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using token and existing account
    Then it is forbidden
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource
    """

