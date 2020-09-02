Feature: GCP Authenticator - Test Token Error Handling

  In this feature we test authentication using malformed tokens.
  Will verify a failure of the authentication request in such a case
  and log of the relevant error.

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
      body:
      - !webservice

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I have host "test-app"
    And I grant group "conjur/authn-gcp/apps" to host "test-app"
    And I set all valid GCP annotations to host "test-app"

  Scenario: Authenticate using a self signed token is denied
    When I save my place in the log file
    And I authenticate with authn-gcp using self signed token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token \(3rdPartyError ='#<JWT::DecodeError: Could not find public key for kid .*>'
    """

  Scenario: Authenticate using a self signed token missing 'kid' header claim is denied
    When I save my place in the log file
    And I authenticate with authn-gcp using no kid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token \(3rdPartyError ='#<JWT::DecodeError: No key id \(kid\) found from token headers>'\)
    """

  Scenario: Authenticate using token with an invalid audience claim is denied
    Given I obtain an invalid_audience GCP identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using obtained token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00067E 'audience' token claim .* is invalid. The format should be 'conjur/<account-name>/<host-id>'
    """

  Scenario: Missing GCP access token is a bad request
    Given I save my place in the log file
    When I authenticate with authn-gcp using no token and existing account
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  Scenario: Empty GCP access token is a bad request
    Given I save my place in the log file
    When I authenticate with authn-gcp using empty token and existing account
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  # "authn-gcp/project-id" annotation is set because at least one of the annotations is expected.
  # we do not test with other annotations as the test will fail on the token validation
  Scenario: Authenticate using token in standard format is denied
    When I have host "project-id-only-test-app"
    And I grant group "conjur/authn-gcp/apps" to host "project-id-only-test-app"
    And I set "authn-gcp/project-id" annotation to host "project-id-only-test-app"
    And I save my place in the log file
    And I obtain a standard_format GCP identity token
    And I authenticate with authn-gcp using obtained token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
     CONJ00068E Claim 'google/compute_engine/project_id' not found or empty in token
    """

  # "authn-gcp/project-id" annotation is set because at least one of the annotations is expected.
  Scenario: Host not in permitted group is denied
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-gcp
      body:
      - !webservice

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read ]
        resource: !webservice
    """
    And I set "authn-gcp/project-id" annotation to host "test-app"
    And I save my place in the log file
    And I obtain a valid GCP identity token
    When I authenticate with authn-gcp using valid token and existing account
    Then it is forbidden
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'host/test-app' does not have 'authenticate' privilege on cucumber:webservice:conjur/authn-gcp
    """
