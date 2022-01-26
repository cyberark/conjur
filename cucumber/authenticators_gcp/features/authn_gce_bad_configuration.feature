@authenticators_gcp
Feature: GCP Authenticator - GCE flow, test malformed configuration

  In this feature we define a GCP authenticator with a malformed configuration.
  Each test will verify a failure of the authentication request in such a case
  and log the relevant error for the user to re-configure the authenticator
  properly.

  Background:
    Given I obtain a valid GCE identity token

  @negative @acceptance
  Scenario: Webservice is missing in policy gets denied
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
      body:

      - !group apps
    """
    And I have host "test-app"
    And I set all valid GCE annotations to host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCE token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00005E Webservice 'authn-gcp' not found
    """

  @negative @acceptance
  Scenario: Webservice with read and no authenticate permission in policy is denied
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
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
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCE token and existing account
    Then it is forbidden
    And The following matches the log after my savepoint:
    """
    CONJ00006E .* does not have 'authenticate' privilege on .*>
    """
