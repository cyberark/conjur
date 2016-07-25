@logged-in
Feature: Validating specific privileges

  Background:
    Given a resource
    And a new user "bob"
    And I permit user "bob" to "fry" it

  Scenario: I confirm that the role can perform the granted action
    When I check if user "bob" can "fry" it
    Then the result is true
    
  Scenario: The new role can confirm that it may perform the granted action
    When I login as "bob"
    And I check if I can "fry" it
    Then the result is true
      
  Scenario: I cannot see resources to which I am not permitted
    When I check if user "bob" can "freeze" it
    Then the result is false
