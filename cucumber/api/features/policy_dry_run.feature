@api
Feature: Dry Run Policies

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user avogadro

    - !policy
      id: dev
      owner: !user avogadro
      body:
      - !policy
        id: db
    """
    And I login as "avogadro"
    And I successfully POST "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable a
    - !variable
      id: b
      kind: password
    - !user
        id: existing-user-for-create
        annotations: 
          description: "This is an existing user for the create scenario"
    - !user
        id: existing-user-for-update
        annotations: 
          description: "This is an existing user for the update scenario"
    - !variable
        id: existing-variable-for-update
        annotations: 
          description: "This is an existing variable for the update scenario"
    - !user
        id: existing-user-for-replace
        annotations: 
          description: "This is an existing user for the replace scenario"
    - !variable
        id: existing-variable-for-replace
        annotations: 
          description: "This is an existing variable for the replace scenario"
    """

  Scenario: When an invalid policy is loaded an error and a recommendation are reported.
    When I dry run POST "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
   - !!str, xxx

    """
    Then the HTTP response status code is 422
    And the status is "Invalid YAML"
    And the validation error includes "did not find expected whitespace or line break"
    And the enhanced error includes "Only one node can be defined per line."

  Scenario: When a valid policy is loaded the status is reported as Valid YAML.
    When I dry run POST "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
    - !user bob
    - !user
        id: existing-user-for-create
        annotations: 
          new_annotation: "This is a new annotation on an existing user"
    """
    Then the HTTP response status code is 200
    And the status is "Valid YAML"
    And the JSON should be:
    """
    {
      "status": "Valid YAML",
      "created": {
        "items": [
          {
            "identifier": "cucumber:user:bob@dev-db",
            "id": "bob@dev-db",
            "type": "user",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permissions": {},
            "annotations": {},
            "members": [
              "cucumber:policy:dev/db"
            ],
            "memberships": [],
            "restricted_to": []
          }
        ]
      },
      "updated": {
        "before": {
          "items": [
            {
              "identifier": "cucumber:policy:dev/db",
              "id": "dev/db",
              "type": "policy",
              "owner": "cucumber:policy:dev",
              "policy": "cucumber:policy:root",
              "permissions": {},
              "annotations": {},
              "members": [
                "cucumber:policy:dev"
              ],
              "memberships": [
                "cucumber:user:existing-user-for-create@dev-db",
                "cucumber:user:existing-user-for-replace@dev-db",
                "cucumber:user:existing-user-for-update@dev-db"
              ],
              "restricted_to": []
            },
            {
              "identifier": "cucumber:user:existing-user-for-create@dev-db",
              "id": "existing-user-for-create@dev-db",
              "type": "user",
              "owner": "cucumber:policy:dev/db",
              "policy": "cucumber:policy:dev/db",
              "permissions": {},
              "annotations": {
                "description": "This is an existing user for the create scenario"
              },
              "members": [
                "cucumber:policy:dev/db"
              ],
              "memberships": [],
              "restricted_to": []
            }
          ]
        },
        "after": {
          "items": [
            {
              "identifier": "cucumber:policy:dev/db",
              "id": "dev/db",
              "type": "policy",
              "owner": "cucumber:policy:dev",
              "policy": "cucumber:policy:root",
              "permissions": {},
              "annotations": {},
              "members": [
                "cucumber:policy:dev"
              ],
              "memberships": [
                "cucumber:user:existing-user-for-create@dev-db",
                "cucumber:user:existing-user-for-replace@dev-db",
                "cucumber:user:existing-user-for-update@dev-db",
                "cucumber:user:bob@dev-db"
              ],
              "restricted_to": []
            },
            {
              "identifier": "cucumber:user:existing-user-for-create@dev-db",
              "id": "existing-user-for-create@dev-db",
              "type": "user",
              "owner": "cucumber:policy:dev/db",
              "policy": "cucumber:policy:dev/db",
              "permissions": {},
              "annotations": {
                "description": "This is an existing user for the create scenario",
                "new_annotation": "This is a new annotation on an existing user"
              },
              "members": [
                "cucumber:policy:dev/db"
              ],
              "memberships": [],
              "restricted_to": []
            }
          ]
        }
      },
      "deleted": {
        "items": []
      }
    }
    """

  Scenario: When a policy is dry run it does not create new or alter existing conjur records.
    When I successfully POST "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
    - !user alice
    """
    And I GET "/resources/cucumber/user/alice"
    Then the HTTP response status code is 404
    When I successfully POST "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable DoesNotTouch
    """
    And I successfully PUT "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
    - !delete
      record: !variable DoesNotTouch
    """
    And I successfully GET "/resources/cucumber/variable"
    Then the resource list should contain "variable" "dev/db/DoesNotTouch"
    When I successfully PUT "/policies/cucumber/policy/dev/db" with body:
    """
    - !delete
      record: !variable DoesNotTouch
    """
    And I successfully GET "/resources/cucumber/variable"
    Then the resource list should not contain "variable" "dev/db/DoesNotTouch"

  # This needs to be updated when these go in:
  # - CNJR-6108 (deletes resources)
  Scenario: When a valid policy is updated the status is reported as Valid YAML.
    When I successfully PATCH "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
    - !user
        id: existing-user-for-update
        annotations: 
          description: "This is an updated description"
    - !group new-group-for-update
    - !grant
        role: !group new-group-for-update
        member: !user existing-user-for-update
    - !variable new-variable-for-update
    - !permit
        role: !group new-group-for-update
        privileges: [ read, execute, delete ]
        resource: !variable new-variable-for-update
    - !delete
        record: !variable existing-variable-for-update
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {
      "status": "Valid YAML",
      "created": {
        "items": [
          {
            "identifier": "cucumber:group:dev/db/new-group-for-update",
            "id": "dev/db/new-group-for-update",
            "type": "group",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permissions": {
              "delete": [
                "cucumber:variable:dev/db/new-variable-for-update"
              ],
              "execute": [
                "cucumber:variable:dev/db/new-variable-for-update"
              ],
              "read": [
                "cucumber:variable:dev/db/new-variable-for-update"
              ]
            },
            "annotations": {},
            "members": [
              "cucumber:policy:dev/db",
              "cucumber:user:existing-user-for-update@dev-db"
            ],
            "memberships": [],
            "restricted_to": []
          },
          {
            "identifier": "cucumber:variable:dev/db/new-variable-for-update",
            "id": "dev/db/new-variable-for-update",
            "type": "variable",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permitted": {
              "delete": [
                "cucumber:group:dev/db/new-group-for-update"
              ],
              "execute": [
                "cucumber:group:dev/db/new-group-for-update"
              ],
              "read": [
                "cucumber:group:dev/db/new-group-for-update"
              ]
            },
            "annotations": {}
          }
        ]
      },
      "updated": {
        "before": {
          "items": [
            {
              "identifier": "cucumber:policy:dev/db",
              "id": "dev/db",
              "type": "policy",
              "owner": "cucumber:policy:dev",
              "policy": "cucumber:policy:root",
              "permissions": {},
              "annotations": {},
              "members": [
                "cucumber:policy:dev"
              ],
              "memberships": [
                "cucumber:user:existing-user-for-create@dev-db",
                "cucumber:user:existing-user-for-replace@dev-db",
                "cucumber:user:existing-user-for-update@dev-db"
              ],
              "restricted_to": []
            },
            {
              "identifier": "cucumber:user:existing-user-for-update@dev-db",
              "id": "existing-user-for-update@dev-db",
              "type": "user",
              "owner": "cucumber:policy:dev/db",
              "policy": "cucumber:policy:dev/db",
              "permissions": {},
              "annotations": {
                "description": "This is an existing user for the update scenario"
              },
              "members": [
                "cucumber:policy:dev/db"
              ],
              "memberships": [],
              "restricted_to": []
            }
          ]
        },
        "after": {
          "items": [
            {
              "identifier": "cucumber:policy:dev/db",
              "id": "dev/db",
              "type": "policy",
              "owner": "cucumber:policy:dev",
              "policy": "cucumber:policy:root",
              "permissions": {},
              "annotations": {},
              "members": [
                "cucumber:policy:dev"
              ],
              "memberships": [
                "cucumber:user:existing-user-for-create@dev-db",
                "cucumber:user:existing-user-for-replace@dev-db",
                "cucumber:user:existing-user-for-update@dev-db",
                "cucumber:group:dev/db/new-group-for-update"
              ],
              "restricted_to": []
            },
            {
              "identifier": "cucumber:user:existing-user-for-update@dev-db",
              "id": "existing-user-for-update@dev-db",
              "type": "user",
              "owner": "cucumber:policy:dev/db",
              "policy": "cucumber:policy:dev/db",
              "permissions": {},
              "annotations": {
                "description": "This is an updated description"
              },
              "members": [
                "cucumber:policy:dev/db"
              ],
              "memberships": [
                "cucumber:group:dev/db/new-group-for-update"
              ],
              "restricted_to": []
            }
          ]
        }
      },
      "deleted": {
        "items": [
          {
            "identifier": "cucumber:variable:dev/db/existing-variable-for-update",
            "id": "dev/db/existing-variable-for-update",
            "type": "variable",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permitted": {},
            "annotations": {
              "description": "This is an existing variable for the update scenario"
            }
          }
        ]
      }
    }
    """

  # This needs to be updated when these go in:
  # - CNJR-6108 (deletes resources)
  Scenario: When a valid policy is replaced the status is reported as Valid YAML.
    When I successfully PUT "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
    - !user
        id: existing-user-for-replace
        annotations: 
          description: "This is an updated description"
    - !group new-group-for-replace
    - !grant
        role: !group new-group-for-replace
        member: !user existing-user-for-replace
    - !variable new-variable-for-replace
    - !permit
        role: !group new-group-for-replace
        privileges: [ read, execute, delete ]
        resource: !variable new-variable-for-replace
    - !delete
        record: !variable existing-variable-for-replace
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {
      "status": "Valid YAML",
      "created": {
        "items": [
          {
            "identifier": "cucumber:group:dev/db/new-group-for-replace",
            "id": "dev/db/new-group-for-replace",
            "type": "group",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permissions": {
              "delete": [
                "cucumber:variable:dev/db/new-variable-for-replace"
              ],
              "execute": [
                "cucumber:variable:dev/db/new-variable-for-replace"
              ],
              "read": [
                "cucumber:variable:dev/db/new-variable-for-replace"
              ]
            },
            "annotations": {},
            "members": [
              "cucumber:policy:dev/db",
              "cucumber:user:existing-user-for-replace@dev-db"
            ],
            "memberships": [],
            "restricted_to": []
          },
          {
            "identifier": "cucumber:variable:dev/db/new-variable-for-replace",
            "id": "dev/db/new-variable-for-replace",
            "type": "variable",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permitted": {
              "delete": [
                "cucumber:group:dev/db/new-group-for-replace"
              ],
              "execute": [
                "cucumber:group:dev/db/new-group-for-replace"
              ],
              "read": [
                "cucumber:group:dev/db/new-group-for-replace"
              ]
            },
            "annotations": {}
          }
        ]
      },
      "updated": {
        "before": {
          "items": [
            {
              "identifier": "cucumber:policy:dev/db",
              "id": "dev/db",
              "type": "policy",
              "owner": "cucumber:policy:dev",
              "policy": "cucumber:policy:root",
              "permissions": {},
              "annotations": {},
              "members": [
                "cucumber:policy:dev"
              ],
              "memberships": [
                "cucumber:user:existing-user-for-create@dev-db",
                "cucumber:user:existing-user-for-replace@dev-db",
                "cucumber:user:existing-user-for-update@dev-db"
              ],
              "restricted_to": []
            },
            {
              "identifier": "cucumber:user:existing-user-for-replace@dev-db",
              "id": "existing-user-for-replace@dev-db",
              "type": "user",
              "owner": "cucumber:policy:dev/db",
              "policy": "cucumber:policy:dev/db",
              "permissions": {},
              "annotations": {
                "description": "This is an existing user for the replace scenario"
              },
              "members": [
                "cucumber:policy:dev/db"
              ],
              "memberships": [],
              "restricted_to": []
            }
          ]
        },
        "after": {
          "items": [
            {
              "identifier": "cucumber:policy:dev/db",
              "id": "dev/db",
              "type": "policy",
              "owner": "cucumber:policy:dev",
              "policy": "cucumber:policy:root",
              "permissions": {},
              "annotations": {},
              "members": [
                "cucumber:policy:dev"
              ],
              "memberships": [
                "cucumber:user:existing-user-for-replace@dev-db",
                "cucumber:group:dev/db/new-group-for-replace"
              ],
              "restricted_to": []
            },
            {
              "identifier": "cucumber:user:existing-user-for-replace@dev-db",
              "id": "existing-user-for-replace@dev-db",
              "type": "user",
              "owner": "cucumber:policy:dev/db",
              "policy": "cucumber:policy:dev/db",
              "permissions": {},
              "annotations": {
                "description": "This is an updated description"
              },
              "members": [
                "cucumber:policy:dev/db"
              ],
              "memberships": [
                "cucumber:group:dev/db/new-group-for-replace"
              ],
              "restricted_to": []
            }
          ]
        }
      },
      "deleted": {
        "items": [
          {
            "identifier": "cucumber:user:existing-user-for-create@dev-db",
            "id": "existing-user-for-create@dev-db",
            "type": "user",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permissions": {},
            "annotations": {
              "description": "This is an existing user for the create scenario"
            },
            "members": [
              "cucumber:policy:dev/db"
            ],
            "memberships": [],
            "restricted_to": []
          },
          {
            "identifier": "cucumber:user:existing-user-for-update@dev-db",
            "id": "existing-user-for-update@dev-db",
            "type": "user",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permissions": {},
            "annotations": {
              "description": "This is an existing user for the update scenario"
            },
            "members": [
              "cucumber:policy:dev/db"
            ],
            "memberships": [],
            "restricted_to": []
          },
          {
            "identifier": "cucumber:variable:dev/db/a",
            "id": "dev/db/a",
            "type": "variable",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permitted": {},
            "annotations": {}
          },
          {
            "identifier": "cucumber:variable:dev/db/b",
            "id": "dev/db/b",
            "type": "variable",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permitted": {},
            "annotations": {
              "conjur/kind": "password"
            }
          },
          {
            "identifier": "cucumber:variable:dev/db/existing-variable-for-replace",
            "id": "dev/db/existing-variable-for-replace",
            "type": "variable",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permitted": {},
            "annotations": {
              "description": "This is an existing variable for the replace scenario"
            }
          },
          {
            "identifier": "cucumber:variable:dev/db/existing-variable-for-update",
            "id": "dev/db/existing-variable-for-update",
            "type": "variable",
            "owner": "cucumber:policy:dev/db",
            "policy": "cucumber:policy:dev/db",
            "permitted": {},
            "annotations": {
              "description": "This is an existing variable for the update scenario"
            }
          }
        ]
      }
    }
    """
