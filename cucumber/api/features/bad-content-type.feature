@api
@logged-in
Feature: Test to allow bad content types in

  @acceptance
  Scenario: I pass in a valid content type and it works successfully
    Given I set the "Content-Type" header to "text/plain"
    When I successfully GET "/resources/cucumber"
    Then the HTTP response status code is 200

  @acceptance
  Scenario: I pass in an invalid content type and it works successfully
    Given I set the "Content-Type" header to "text\\plain"
    When I successfully GET "/resources/cucumber"
    Then the HTTP response status code is 200

  @acceptance
  Scenario: I pass in an empty content type and it works successfully
    Given I set the "Content-Type" header to ""
    When I successfully GET "/resources/cucumber"
    Then the HTTP response status code is 200
