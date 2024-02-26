@api
Feature: Deleting objects and relationships.

  Removal of policy tree should have entries in audit log for each level

  Background:
    Given I am the super-user
    And I successfully POST "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: data
      body: []
    """
    And I successfully POST "/policies/cucumber/policy/data" with body:
    """
    - !policy
      id: outer
      body: []
    """
    And I successfully POST "/policies/cucumber/policy/data/outer" with body:
    """
    - !variable outer_secret
    - !policy
      id: inner
      body: []
    """
    And I successfully POST "/policies/cucumber/policy/data/outer/inner" with body:
    """
    - !variable inner_secret
    """

  @smoke
  Scenario: Deleting nested policy keeps audit log for removal of nested entries
    Given I save my place in the audit log file for remote
    And I successfully PUT "/policies/cucumber/policy/data" with body:
    """
    - !variable replacement
    """
    Then there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 resource="cucumber:policy:data/outer/inner"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      [policy@43868 id="cucumber:policy:data" version="2"]
      cucumber:user:admin removed resource cucumber:policy:data/outer
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:policy:data/outer/inner"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      [policy@43868 id="cucumber:policy:data" version="2"]
      cucumber:user:admin removed role cucumber:policy:data/outer/inner
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 resource="cucumber:variable:data/outer/inner/inner_secret"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      [policy@43868 id="cucumber:policy:data" version="2"]
      cucumber:user:admin removed resource cucumber:variable:data/outer/inner/inner_secret
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:policy:data/outer/inner" owner="cucumber:policy:data/outer"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      [policy@43868 id="cucumber:policy:data" version="2"]
      cucumber:user:admin removed ownership of cucumber:policy:data/outer in cucumber:policy:data/outer/inner
    """
