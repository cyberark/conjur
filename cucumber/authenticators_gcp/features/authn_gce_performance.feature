@authenticators_gcp
Feature: GCP Authenticator - GCE flow, Performance tests

  In this feature we test that GCP Authenticator performance is meeting
  the SLA. We run multiple authn-gcp requests in multiple threads and verify
  that the average time of a request is no more that the agreed time.
  We test both successful requests and unsuccessful requests.

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
    And I am the super-user
    And I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I set all valid GCE annotations to host "test-app"
    And I obtain a valid GCE identity token

  @performance
  Scenario: successful requests
    When I authenticate 1000 times in 10 threads with authn-gcp using valid GCE token and existing account
    Then The avg authentication request responds in less than 0.75 seconds

  @performance @negative
  Scenario: Unsuccessful requests with invalid resource restrictions
    Given I have host "no-annotations-app"
    And I grant group "conjur/authn-gcp/apps" to host "no-annotations-app"
    When I authenticate 1000 times in 10 threads with authn-gcp using valid GCE token and existing account
    Then The avg authentication request responds in less than 0.75 seconds
