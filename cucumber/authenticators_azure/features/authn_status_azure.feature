@authenticators_azure
Feature: Azure Authenticator - Status Check

  @smoke
  Scenario: A properly configured Azure authenticator returns a successful response
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !variable
        id: provider-uri

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: operators
        annotations:
          description: Group of users who can check the status of the authn-azure/prod authenticator

      - !permit
        role: !group operators
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-azure/prod/users
      member: !user alice

    - !grant
      role: !group conjur/authn-azure/prod/operators
      member: !user alice
    """
    And I am the super-user
    And I successfully set Azure provider-uri variable with the correct values
    And I login as "alice"
    When I GET "/authn-azure/prod/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @negative @acceptance
  Scenario: A non-responsive Azure AD provider returns a 500 response
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !variable
        id: provider-uri

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: operators
        annotations:
          description: Group of users who can check the status of the authn-azure/prod authenticator

      - !permit
        role: !group operators
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-azure/prod/users
      member: !user alice

    - !grant
      role: !group conjur/authn-azure/prod/operators
      member: !user alice
    """
    And I am the super-user
    And I successfully set Azure provider-uri variable to value "https://not-responsive.com"
    And I login as "alice"
    When I GET "/authn-azure/prod/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "ProviderDiscoveryFailed: CONJ00011E"

  @negative @acceptance
  Scenario: provider-uri variable is missing and a 500 error response is returned
    Given I load a policy:
     """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: operators
        annotations:
          description: Group of users who can check the status of the authn-azure/prod authenticator

      - !permit
        role: !group operators
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-azure/prod/users
      member: !user alice

    - !grant
      role: !group conjur/authn-azure/prod/operators
      member: !user alice
    """
    And I am the super-user
    And I login as "alice"
    When I GET "/authn-azure/prod/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "RequiredResourceMissing: CONJ00036E"

  # TODO: add this tes when issue #1085 is done
#  Scenario: provider-uri value has not been set and a 500 error response is returned

