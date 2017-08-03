# The feature uses step definitions of api cuke
Feature: Get status of the Conjur CE instance

  Scenario: The status page loads successfully
    When I visit the Conjur CE status page
    Then I should see "Your Conjur CE server is running!" on the status page
    And I should see the current Conjur CE version
