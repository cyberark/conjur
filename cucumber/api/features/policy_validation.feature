@api
Feature: Validating policies

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
    """

  Scenario: When an invalid policy is loaded an error and a recommendation are reported.
    When I validate POST "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
   - !!str, xxx

    """
    Then the HTTP response status code is 422
    And the status is "Invalid YAML"
    And the validation error includes "did not find expected whitespace or line break"
    # And the enhanced error includes "Only one node can be defined per line."

  Scenario: When a valid policy is loaded the status is reported as Valid YAML.
    When I validate POST "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
    - !user bob
    """
    Then the HTTP response status code is 200
    And the status is "Valid YAML"
    And there are no errors

  Scenario: When a policy is validated it does not alter existing conjur records.
    When I successfully POST "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable ValidateDoesNotTouch
    """
    And I successfully PUT "/policies/cucumber/policy/dev/db?dryRun=true" with body:
    """
    - !delete
      record: !variable ValidateDoesNotTouch
    """
    And I successfully GET "/resources/cucumber/variable"
    Then the resource list should contain "variable" "dev/db/ValidateDoesNotTouch"
    When I successfully PUT "/policies/cucumber/policy/dev/db" with body:
    """
    - !delete
      record: !variable ValidateDoesNotTouch
    """
    And I successfully GET "/resources/cucumber/variable"
    Then the resource list should not contain "variable" "dev/db/ValidateDoesNotTouch"

  @smoke
  Scenario: When a policy is validated it is audited and not loaded.
    Given I am the super-user
    And I save my place in the audit log file for remote
    And I successfully POST "/policies/cucumber/policy/root?dryRun=true" with body:
    """
    - !user alice
    """
    Then there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="validate"]
      cucumber:user:admin validated {}
    """
    When I GET "/resources/cucumber/user/alice"
    Then the HTTP response status code is 404
