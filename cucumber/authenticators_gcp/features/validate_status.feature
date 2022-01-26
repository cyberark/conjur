@authenticators_gcp
Feature: GCP Authenticator - Status Check

  @smoke
  Scenario: A properly configured GCP authenticator returns a successful response
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
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
        id: managers
        annotations:
          description: Group of users who can check the status of the authn-gcp authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-gcp/users
      member: !user alice

    - !grant
      role: !group conjur/authn-gcp/managers
      member: !user alice
    """
    And I am the super-user
    And I login as "alice"
    When I GET "/authn-gcp/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds
