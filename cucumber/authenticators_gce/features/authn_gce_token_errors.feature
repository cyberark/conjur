Feature: GCE Authenticator - Test Token Error Handling

  In this feature we test authentication using malformed tokens.
  Will verify a failure of the authentication request in such a case
  and log of the relevant error.

  Background:
    Given a policy:
    """
    - !policy
      id: conjur/authn-gce
      body:
      - !webservice

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I have host "test-app"
    And I grant group "conjur/authn-gce/apps" to host "test-app"
    And I set all valid GCE annotations to host "test-app"

  Scenario: Authenticate using a self signed token is denied
    When I save my place in the log file
    And I authenticate with authn-gce using self signed token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token \(3rdPartyError ='#<JWT::DecodeError: Could not find public key for kid .*>'
    """

  Scenario: Authenticate using a self signed token missing 'kid' header claim is denied
    When I save my place in the log file
    And I authenticate with authn-gce using no kid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token \(3rdPartyError ='#<JWT::DecodeError: No key id \(kid\) found from token headers>'\)
    """

  Scenario: Authenticate using token with an invalid audience claim is denied
    When I save my place in the log file
    And I obtain a GCE identity token in full format with audience claim value: "invalid-audience"
    And I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00067E 'audience' token claim invalid-audience is invalid. The format should be 'conjur/<account_name>/<host_id>'
    """

  Scenario: Authenticate using token with an invalid audience claim format missing 'conjur' part is denied
    When I save my place in the log file
    And I obtain a GCE identity token in full format with audience claim value: "cucumber/host/test-app"
    And I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00067E 'audience' token claim cucumber/host/test-app is invalid
    """

  Scenario: Authenticate using token with an invalid audience claim format missing 'account' part is denied
    When I save my place in the log file
    And I obtain a GCE identity token in full format with audience claim value: "conjur/host/test-app"
    And I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00067E 'audience' token claim conjur/host/test-app is invalid
    """

  Scenario: Authenticate using token with an invalid audience claim format missing 'host' part is denied
    When I save my place in the log file
    And I obtain a GCE identity token in full format with audience claim value: "conjur/cucumber/test-app"
    And I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00007E 'test-app' not found
    """

  Scenario: Missing GCE access token is a bad request
    Given I save my place in the log file
    When I authenticate with authn-gce using no token and existing account
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  Scenario: Empty GCE access token is a bad request
    Given I save my place in the log file
    When I authenticate with authn-gce using empty token and existing account
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  # Only project-id is because at leas one annotation is required and the scenario is testing invalid
  # token format
  Scenario: Authenticate using token in standard format is denied
    When I have host "project-id-only-test-app"
    And I grant group "conjur/authn-gce/apps" to host "project-id-only-test-app"
    And I set "authn-gce/project-id" annotation to host "project-id-only-test-app"
    And I save my place in the log file
    And I obtain a GCE identity token in standard format with audience claim value: "conjur/cucumber/host/project-id-only-test-app"
    And I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
     CONJ00068E Claim 'google/compute_engine/project_id' not found or empty in token
    """
