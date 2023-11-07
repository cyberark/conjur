@authenticators_k8s
Feature: Kubernetes Authenticator - Status Check

  @smoke
  Scenario: A properly configured Kubernetes authenticator returns a successful response
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-k8s/test
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
          description: Group of users who can check the status of the authn-k8s authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-k8s/test/users
      member: !user alice

    - !grant
      role: !group conjur/authn-k8s/test/managers
      member: !user alice
    """
    And I login as "alice"
    When I GET "/authn-k8s/test/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds
