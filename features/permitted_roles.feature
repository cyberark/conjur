@logged-in
Feature: Listing permitted roles on resources

  Background:
    Given a resource

  Scenario: Initial permitted roles is just the owner, and the roles which have the owner.
    When I list the roles who can "fry" it
    
