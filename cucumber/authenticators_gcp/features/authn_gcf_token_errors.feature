@authenticators_gcp
Feature: GCP Authenticator - GCF flow, test token error hwahtandling

  In this feature we test authentication using malformed tokens.
  Will verify a failure of the authentication request in such a case
  and log of the relevant error.

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
      body:
      - !webservice

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"

  @negative @acceptance
  Scenario: Token with service-account-id claim that does not match annotation is denied
    Given I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-id" annotation with value: "unknown-service-account-id" to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'service-account-id' does not match with the corresponding value in the request
    """

  @negative @acceptance
  Scenario: Token with service-account-email claim that does not match annotation is denied
    Given I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-email" annotation with value: "unknown-service-account-email" to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'service-account-email' does not match with the corresponding value in the request
    """

  @negative @acceptance
  Scenario: Token with valid service-account-id claim and service-account-email claim that does not match annotation is denied
    Given I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-id" GCF annotation to host "test-app"
    And I set "authn-gcp/service-account-email" annotation with value: "unknown-service-account-email" to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'service-account-email' does not match with the corresponding value in the request
    """

  @negative @acceptance
  Scenario: Token with valid service-account-email claim and service-account-id claim that does not match annotation is denied
    And I set "authn-gcp/service-account-email" GCF annotation to host "test-app"
    And I set "authn-gcp/service-account-id" annotation with value: "unknown-service-account-id" to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'service-account-id' does not match with the corresponding value in the request
    """

  @negative @acceptance
  Scenario: Token with project-id host annotation is denied
    And I set all valid GCF annotations to host "test-app"
    And I set "authn-gcp/project-id" GCF annotation to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00068E Claim 'project-id' is missing from Google's JWT token
    """

  @negative @acceptance
  Scenario: Token with instance-name host annotation is denied
    And I set all valid GCF annotations to host "test-app"
    And I set "authn-gcp/instance-name" GCF annotation to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using a valid GCF identity token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00068E Claim 'instance-name' is missing from Google's JWT token
    """
