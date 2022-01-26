@policy
Feature: Rake task to load Conjur policy

Conjur includes a Rake task (`rake policy:load`) for loading policies from 
within the Conjur container. This rake task is used by the `conjurctl policy 
load`

  @smoke
  Scenario: Load a simple policy using `rake policy:load`
  
    When I load a policy from file "policy.yml" using conjurctl
    Then user "test" exists

    