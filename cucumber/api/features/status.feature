# The feature uses step definitions of api cuke
Feature: Get status of the Conjur CE instance

  Scenario: The status page loads successfully
    When I GET "/"
    Then the html result contains "<title>Conjur CE Status</title>"
    And the html result contains current possum version
