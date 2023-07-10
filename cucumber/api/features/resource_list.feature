@api
@logged-in
Feature: List resources with various types of filtering

  Background:
    Given I am a user named "alice"
    And I create 3 new resources

  @smoke
  Scenario: The resource list includes a new resource.

    The most basic resource listing route returns all resources in an account.

    Given I save my place in the audit log file for remote
    When I successfully GET "/resources/cucumber"
    Then the resource list should include the newest resources
    And there is an audit record matching:
    """
      <86>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:alice successfully listed resources with parameters: {:account=>"cucumber"}
    """

  @smoke
  Scenario: The resource list can be filtered by resource kind.
    Given I create a new "custom" resource
    And I save my place in the audit log file for remote
    When I successfully GET "/resources/cucumber/custom"
    Then the resource list should include the newest resource
    And there is an audit record matching:
    """
      <86>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" kind="custom"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:alice successfully listed resources with parameters: {:account=>"cucumber", :kind=>"custom"}
    """

  @acceptance
  Scenario: The resource list, when filtered by a different resource kind, does not include the newest resource.
    Given I create a new "custom" resource
    And I save my place in the audit log file for remote
    When I successfully GET "/resources/cucumber/uncreated-resource-kind"
    Then the resource list should not include the newest resource
    And there is an audit record matching:
    """
      <86>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" kind="uncreated-resource-kind"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:alice successfully listed resources with parameters: {:account=>"cucumber", :kind=>"uncreated-resource-kind"}
    """

  @smoke
  Scenario: The resource list is searched and contains a resource with a matching resource id.
    Given I create a new resource called "target"
    And I save my place in the audit log file for remote
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource
    And there is an audit record matching:
    """
      <86>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" kind="test-resource" search="target"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:alice successfully listed resources with parameters: {:account=>"cucumber", :kind=>"test-resource", :search=>"target"}
    """

  @smoke
  Scenario: The resource list is searched and contains a resource with a matching annotation.
    Given I create a new resource
    And I add an annotation value of "target" to the resource
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @acceptance
  Scenario: The resource list is searched and the matched resource id contains a period.
    Given I create a new resource called "target.resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @acceptance
  Scenario: The resource list is searched and the matched resource id contains a slash separator.
    Given I create a new resource called "target/resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @acceptance
  Scenario: The resource list is searched and the matched resource id contains a dash separator.
    Given I create a new resource called "target-resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @smoke
  Scenario: The resource list is searched and contains multiple resources with matching resource ids.
    Given I create a new searchable resource called "target_1"
    And I create a new searchable resource called "target_2"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resources

  @smoke
  Scenario: The resource list is limited to a certain number of results.
    When I successfully GET "/resources/cucumber/test-resource?limit=1"
    Then I receive 1 resources

  @negative @acceptance
  Scenario: The resource list cannot be limited with non numeric value
    Given I save my place in the audit log file for remote
    When I GET "/resources/cucumber/test-resource?limit=abc"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'limit' contains an invalid value. 'limit' must be a positive integer."
    And there is an audit record matching:
    """
      <84>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" kind="test-resource" limit="abc"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="list"]
      cucumber:user:alice failed to list resources with parameters: {:account=>"cucumber", :kind=>"test-resource", :limit=>"abc"}:
      'limit' contains an invalid value. 'limit' must be a positive integer
    """

  @negative @acceptance
  Scenario: The resource list cannot be limited with zero
    Given I save my place in the audit log file for remote
    When I GET "/resources/cucumber/test-resource?limit=0"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'limit' contains an invalid value. 'limit' must be a positive integer."
    And there is an audit record matching:
    """
      <84>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" kind="test-resource" limit="0"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="list"]
      cucumber:user:alice failed to list resources with parameters: {:account=>"cucumber", :kind=>"test-resource", :limit=>"0"}:
      'limit' contains an invalid value. 'limit' must be a positive integer
    """

  @negative @acceptance
  Scenario: The resource list cannot be limited with negative integer
    When I GET "/resources/cucumber/test-resource?limit=-10"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'limit' contains an invalid value. 'limit' must be a positive integer."

  @smoke
  Scenario: The resource list is retrieved starting from a specific offset.
    When I successfully GET "/resources/cucumber/test-resource?offset=1"
    Then I receive 2 resources

  @negative @acceptance
  Scenario: The resource list cannot be retrieved starting from a specific offset with non numeric value
    Given I save my place in the audit log file for remote
    When I GET "/resources/cucumber/test-resource?offset=abc"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."
    And there is an audit record matching:
    """
      <84>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" kind="test-resource" offset="abc"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="list"]
      cucumber:user:alice failed to list resources with parameters: {:account=>"cucumber", :kind=>"test-resource", :offset=>"abc"}:
      'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0
    """

  @negative @acceptance
  Scenario: The resource list cannot be retrieved starting from a specific offset with negative integer
    When I GET "/resources/cucumber/test-resource?offset=-10"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."

  @smoke
  Scenario: The resource list is retrieved starting from a specific offset and is limited
    Given I save my place in the audit log file for remote
    When I successfully GET "/resources/cucumber/test-resource?offset=1&limit=1"
    Then I receive 1 resources
    And there is an audit record matching:
    """
      <86>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" kind="test-resource" limit="1" offset="1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:alice successfully listed resources with parameters: {:account=>"cucumber", :kind=>"test-resource", :limit=>"1", :offset=>"1"}
    """
  @negative @acceptance
  Scenario: The resource list cannot be retrieved with non numeric limit delimiter
    When I GET "/resources/cucumber/test-resource?offset=1&limit=abc"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'limit' contains an invalid value. 'limit' must be a positive integer."

  @negative @acceptance
  Scenario: The resource list cannot be retrieved with non numeric offset delimiter
    When I GET "/resources/cucumber/test-resource?offset=abc&limit=1"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."

  @smoke
  Scenario: The resource list is counted.
    Given I save my place in the audit log file for remote
    When I successfully GET "/resources/cucumber/test-resource?count=true"
    Then I receive a count of 3
    And there is an audit record matching:
    """
      <86>1 * * conjur * list
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" kind="test-resource" count="true"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:alice successfully listed resources with parameters: {:account=>"cucumber", :kind=>"test-resource", :count=>"true"}
    """
