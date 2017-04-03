Feature: For most commonly used runtime methods, v4-compatible API routes are available.
  
  The environment variable CONJUR_ACCOUNT must be specified on server
  startup to activate this feature.
  
  Scenario: Authenticate.
    
    Conjur v4 route for authentication is `POST /authn/users/:id/authenticate`.
    
    Given I create a new user "alice"
    Then I can POST "/authn/users/alice/authenticate" with plain text body ":alice_api_key"

  @logged-in
  Scenario: Fetch a variable value.
    
    Conjur v4 route for fetching a variable is `POST /variables/:id/value`.
    
    Given I create a new "variable" resource called "db/password"
    Given I set annotation "conjur/mime_type" to "application/json"
    And I successfully POST "/secrets/cucumber/variable/db/password" with body:
    """
    [ "v-1" ]
    """
    When I successfully GET "/variables/db%2Fpassword/value"
    Then the JSON should be:
    """
    [ "v-1" ]
    """
