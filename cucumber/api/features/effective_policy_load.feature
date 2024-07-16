@api
Feature: Loading effective policy

  @acceptance
  Scenario: Loading effective policy for root into root using POST method
    Given I am the super-user
    When I successfully POST "/policies/cucumber/policy/root" with body from file "policy_acme_eff_pol_root.yml"

  @acceptance
  Scenario: Loading effective policy for root into root using PUT method
    Given I am the super-user
    When I successfully PUT "/policies/cucumber/policy/root" with body from file "policy_acme_eff_pol_root.yml"

  @acceptance
  Scenario: Loading effective policy for root into root using PATCH method
    Given I am the super-user
    And I successfully PATCH "/policies/cucumber/policy/root" with body from file "policy_acme_eff_pol_root.yml"

  @acceptance
  Scenario: Loading effective policy for rootpolicy into root using POST method
    Given I am the super-user
    When I successfully POST "/policies/cucumber/policy/root" with body from file "policy_acme_eff_pol.yml"

  @acceptance
  Scenario: Loading effective policy for rootpolicy into root using PUT method
    Given I am the super-user
    When I successfully PUT "/policies/cucumber/policy/root" with body from file "policy_acme_eff_pol.yml"

  @acceptance
  Scenario: Loading effective policy for rootpolicy into root using PATCH method
    Given I am the super-user
    And I successfully PATCH "/policies/cucumber/policy/root" with body from file "policy_acme_eff_pol.yml"
