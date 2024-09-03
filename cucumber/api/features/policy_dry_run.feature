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

  # This needs to be updated when these go in:
  # - CNJR-5841 (creates resources)
  # - CNJR-6108 (updates resources)
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
        "items": []
      },
      "updated": {
        "before": {
          "items": []
        },
        "after": {
          "items": []
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
  # - CNJR-5841 (creates resources)
  # - CNJR-6108 (updates resources)
  # - CNJR-6109 (deletes resources)
  Scenario: When a valid policy is updated the status is reported as Valid YAML.
    When I successfully PUT "/policies/cucumber/policy/dev/db?dryRun=true" with body:
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
        "items": []
      },
      "updated": {
        "before": {
          "items": []
        },
        "after": {
          "items": []
        }
      },
      "deleted": {
        "items": []
      }
    }
    """

  # This needs to be updated when these go in:
  # - CNJR-5841 (creates resources)
  # - CNJR-6108 (updates resources)
  # - CNJR-6109 (deletes resources)
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
        "items": []
      },
      "updated": {
        "before": {
          "items": []
        },
        "after": {
          "items": []
        }
      },
      "deleted": {
        "items": []
      }
    }
    """
