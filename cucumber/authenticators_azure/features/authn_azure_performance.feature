@authenticators_azure
Feature: Azure Authenticator - Performance tests

  In this feature we test that Azure Authenticator performance is meeting
  the SLA. We run multiple authn-azure requests in multiple threads and verify
  that the average time of a request is no more that the agreed time.
  We test both successful requests and unsuccessful requests.

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !variable
        id: provider-uri

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I am the super-user
    And I successfully set Azure provider-uri variable with the correct values
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"

  @performance
  Scenario: successful requests
    And I fetch a non-assigned-identity Azure access token from inside machine
    When I authenticate 1000 times in 10 threads via Azure with token as host "test-app"
    Then The avg authentication request responds in less than 0.75 seconds

  @performance
  Scenario: successful requests with Accept-Encoding base64
    And I fetch a non-assigned-identity Azure access token from inside machine
    When I authenticate 1000 times in 10 threads via Azure with token as host "test-app" with Accept-Encoding header "base64"
    Then The avg authentication request responds in less than 0.75 seconds

  @performance @negative
  Scenario: Unsuccessful requests with an invalid token
    And I fetch a non-assigned-identity Azure access token from inside machine
    When I authenticate 1000 times in 10 threads via Azure with invalid token as host "test-app"
    Then The avg authentication request responds in less than 0.75 seconds

  @performance @negative
  Scenario: Unsuccessful requests with invalid resource restrictions
    Given I have host "no-azure-annotations-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "no-azure-annotations-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    When I authenticate 1000 times in 10 threads via Azure with token as host "no-azure-annotations-app"
    Then The avg authentication request responds in less than 0.75 seconds
