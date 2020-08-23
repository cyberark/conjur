Feature: GCE Authenticator - Status Check

  Scenario: A properly configured GCE authenticator returns a successful response
    Given a policy:
    """
    - !policy
      id: conjur/authn-gce
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
          description: Group of users who can check the status of the authn-gce authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-gce/users
      member: !user alice

    - !grant
      role: !group conjur/authn-gce/managers
      member: !user alice
    """
    And I am the super-user
    And I login as "alice"
    When I GET "/authn-gce/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds
