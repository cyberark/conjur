@api
@logged-in
Feature: List resources for another role
  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice
    - !user bob
    - !policy
      id: dev
      owner: !user alice
      body:
        - !variable dev-var
    - !policy
      id: prod
      owner: !user bob
      body:
        - !variable prod-var
    - !variable
      id: alice-var
      kind: password
    - !variable
      id: group-var
      kind: password
    - !policy
        - !permit
          role: !user alice
          privileges: [read]
          resources: [!variable alice-var]
        - !permit
          role: !user bob
          privileges: [write]
          resources: [!variable alice-var]
        - !group users
        - !grant
          role: !group users
          members:
            - !user alice
        - !permit
          role: !group users
          privileges: [write]
          resources: [!variable group-var]
    """

  @smoke
  Scenario: The resource list can be retrieved for a different role, specified the query parameter role
    Given I save my place in the audit log file for remote
    When I successfully GET "/resources?role=cucumber:user:alice"
    Then the JSON should be:
    """
      [
       {
         "annotations": [],
         "id": "cucumber:policy:dev",
         "owner": "cucumber:user:alice",
         "permissions": [],
         "policy": "cucumber:policy:root",
         "policy_versions": []
       },
       {
         "annotations": [
           {
             "name": "conjur/kind",
             "policy": "cucumber:policy:root",
             "value": "password"
           }
         ],
         "id": "cucumber:variable:alice-var",
         "owner": "cucumber:user:admin",
         "permissions": [
           {
             "policy": "cucumber:policy:root",
             "privilege": "read",
             "role": "cucumber:user:alice"
           }
         ],
         "policy": "cucumber:policy:root",
         "secrets": []
       },
       {
         "annotations": [],
         "id": "cucumber:variable:dev/dev-var",
         "owner": "cucumber:policy:dev",
         "permissions": [],
         "policy": "cucumber:policy:root",
         "secrets": []
       },
       {
         "annotations": [
           {
             "name": "conjur/kind",
             "policy": "cucumber:policy:root",
             "value": "password"
           }
         ],
         "id": "cucumber:variable:group-var",
         "owner": "cucumber:user:admin",
         "permissions": [
           {
             "policy": "cucumber:policy:root",
             "privilege": "write",
             "role": "cucumber:group:users"
           }
         ],
         "policy": "cucumber:policy:root",
         "secrets": []
       }
      ]
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * list
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:user:alice"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed resources with parameters: {:role=>"cucumber:user:alice"}
    """

  @smoke
  Scenario: The resource list can be retrieved for a different role, specified the query parameter acting_as
    When I successfully GET "/resources?acting_as=cucumber:user:alice"
    Then the JSON should be:
    """
      [
       {
         "annotations": [],
         "id": "cucumber:policy:dev",
         "owner": "cucumber:user:alice",
         "permissions": [],
         "policy": "cucumber:policy:root",
         "policy_versions": []
       },
       {
         "annotations": [
           {
             "name": "conjur/kind",
             "policy": "cucumber:policy:root",
             "value": "password"
           }
         ],
         "id": "cucumber:variable:alice-var",
         "owner": "cucumber:user:admin",
         "permissions": [
           {
             "policy": "cucumber:policy:root",
             "privilege": "read",
             "role": "cucumber:user:alice"
           }
         ],
         "policy": "cucumber:policy:root",
         "secrets": []
       },
       {
         "annotations": [],
         "id": "cucumber:variable:dev/dev-var",
         "owner": "cucumber:policy:dev",
         "permissions": [],
         "policy": "cucumber:policy:root",
         "secrets": []
       },
       {
         "annotations": [
           {
             "name": "conjur/kind",
             "policy": "cucumber:policy:root",
             "value": "password"
           }
         ],
         "id": "cucumber:variable:group-var",
         "owner": "cucumber:user:admin",
         "permissions": [
           {
             "policy": "cucumber:policy:root",
             "privilege": "write",
             "role": "cucumber:group:users"
           }
         ],
         "policy": "cucumber:policy:root",
         "secrets": []
       }
      ]
    """

  @negative @acceptance
  Scenario: Attempting to retrieve the resource list for a different role but without giving the account in the ID results in a 403
    Given I save my place in the audit log file for remote
    When I GET "/resources?acting_as=user:alice"
    Then the HTTP response status code is 403
    And there is an audit record matching:
    """
      <84>1 * * conjur * list
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 acting_as="user:alice"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="list"]
      cucumber:user:admin failed to list resources with parameters: {:acting_as=>"user:alice"}:
      The authenticated user lacks the necessary privilege
    """

  @smoke
  Scenario: The resource list can be retrieved for a different group role, specified the query parameter acting_as
    When I successfully GET "/resources?acting_as=cucumber:group:users"
    Then the JSON should be:
    """
      [
        {
          "annotations": [
            {
              "name": "conjur/kind",
              "policy": "cucumber:policy:root",
              "value": "password"
            }
          ],
          "id": "cucumber:variable:group-var",
          "owner": "cucumber:user:admin",
          "permissions": [
            {
              "policy": "cucumber:policy:root",
              "privilege": "write",
              "role": "cucumber:group:users"
            }
          ],
          "policy": "cucumber:policy:root",
          "secrets": []
        }
       ]

    """