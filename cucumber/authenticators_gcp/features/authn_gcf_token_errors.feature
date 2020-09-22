Feature: GCP Authenticator - Test Token Error Handling

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

  Scenario: Token with service-account-id claim that does not match annotation is denied
    Given I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-id" annotation with value: "unknown-service-account-id" to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCF identity token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'authn-gcp/service-account-id' does not match resource in JWT token
    """

  Scenario: Token with service-account-email claim that does not match annotation is denied
    Given I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-email" annotation with value: "unknown-service-account-email" to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCF identity token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'authn-gcp/service-account-email' does not match resource in JWT token
    """

  Scenario: Token with valid service-account-id claim and service-account-email claim that does not match annotation is denied
    Given I remove all annotations from host "test-app"
    And I set "authn-gcp/service-account-id" annotation to function host "test-app"
    And I set "authn-gcp/service-account-email" annotation with value: "unknown-service-account-email" to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCF identity token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'authn-gcp/service-account-email' does not match resource in JWT token
    """

  Scenario: Token with valid service-account-email claim and service-account-id claim that does not match annotation is denied
    And I set "authn-gcp/service-account-email" annotation to function host "test-app"
    And I set "authn-gcp/service-account-id" annotation with value: "unknown-service-account-id" to host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCF identity token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'authn-gcp/service-account-id' does not match resource in JWT token
    """

  Scenario: Token with project-id host annotation is denied
    And I set all valid GCF annotations to host "test-app"
    And I set "authn-gcp/project-id" annotation to function host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCF identity token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00068E Resource restriction 'project-id' does not exists resource in JWT token
    """

  Scenario: Token with instance-name host annotation is denied
    And I set all valid GCF annotations to host "test-app"
    And I set "authn-gcp/instance-name" annotation to function host "test-app"
    And I obtain a valid GCF identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using valid GCF identity token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00068E Resource restriction 'instance-name' does not exists resource in JWT token
    """
