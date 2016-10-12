Feature: Policy load response

  @logged-in-admin
  @clean-policies
  Scenario: API keys of users and hosts created by a new policy are returned in the JSON response.
    When I successfully POST "/policies/:account/policy/bootstrap" with body:
    """
    - !policy
      id: frontend
      body:
      - !layer

    - !user bob
    - !host host-01
    """
    Then the JSON should have "created_roles"
    And the JSON at "created_roles" should have 2 entries
    And the JSON should have "created_roles/cucumber:host:host-01/api_key"
    And the JSON at "created_roles/cucumber:host:host-01/api_key" should be a string
    And the JSON at "version" should be an integer
