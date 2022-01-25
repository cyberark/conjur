@api
Feature: Limit the number of policy versions

  Each update of a policy creates a policy version record and policy log records. This feature limits
  the number of versions in the database to default value of 20 version, older versions are deleted.

  Background:
    Given I am the super-user
    And I successfully POST "/policies/cucumber/policy/root" with body:
    """
      - !policy policy_test_version
    """

  @acceptance
  Scenario: I update a policy multiple times so it exceeds the default policy versions limit and get the default
            limited number of versions in response when I retrieve the policy resource
    Given I save my place in the log file
    And I successfully POST 21 times "/policies/cucumber/policy/policy_test_version" with body:
    """
      - !user bob
    """
    And the HTTP response status code is 201
    And I successfully GET "/resources/cucumber/policy/policy_test_version"
    Then there are 20 "policy_versions" in the response
    And The following appears in the log after my savepoint:
    """
    Deleting policy version: {:version=>1, :resource_id=>"cucumber:policy:policy_test_version",
    """

  @acceptance
  Scenario: DB migration removes policy versions that exceed to limit
    Given I save my place in the log file
    And I successfully POST 21 times "/policies/cucumber/policy/policy_test_version" with body:
    """
      - !user bob
    """    
    And the HTTP response status code is 201
    When I migrate the db
    And I successfully GET "/resources/cucumber/policy/policy_test_version"
    Then there are 20 "policy_versions" in the response
