Feature: Azure Authenticator performance

  Background:
    Given a policy:
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
    And I successfully set Azure variables
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"

  Scenario: successful requests
    And I fetch an Azure access token from inside machine
    When I authenticate 1000 times in 10 threads via Azure with token as host "test-app"
    Then The "avg" Azure Authentication request response time should be less than "0.75" seconds

  Scenario: Unsuccessful requests with an invalid token
    And I fetch an Azure access token from inside machine
    When I authenticate 1000 times in 10 threads via Azure with invalid token as host "test-app"
    Then The "avg" Azure Authentication request response time should be less than "0.75" seconds

  Scenario: Unsuccessful requests with invalid application identity
    Given I have host "no-azure-annotations-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "no-azure-annotations-app"
    And I fetch an Azure access token from inside machine
    When I authenticate 1000 times in 10 threads via Azure with token as host "no-azure-annotations-app"
    Then The "avg" Azure Authentication request response time should be less than "0.75" seconds
