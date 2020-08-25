Feature: GCE Authenticator - Test Malformed Configuration

  In this feature we define a GCE authenticator with a malformed configuration.
  Each test will verify a failure of the authentication request in such a case
  and log the relevant error for the user to re-configure the authenticator
  properly.

  Background:
    Given I obtain a valid GCE identity token

  Scenario: Webservice is missing in policy gets denied
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-gce
      body:

      - !group apps
    """
    And I have host "test-app"
    And I set all valid GCE annotations to host "test-app"
    And I grant group "conjur/authn-gce/apps" to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00005E Webservice 'authn-gce' not found
    """

  Scenario: Webservice with read and no authenticate permission in policy is denied
    Given I load a policy:
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
    And I have host "test-app"
    And I set all valid GCE annotations to host "test-app"
    And I grant group "conjur/authn-gce/apps" to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then it is forbidden
    And The following appears in the log after my savepoint:
    """
    CONJ00006E .* does not have 'authenticate' privilege on .*>
    """
