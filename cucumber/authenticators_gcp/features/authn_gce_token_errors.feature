@authenticators_gcp
Feature: GCP Authenticator - GCE flow, test token error handling

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
    And I set all valid GCE annotations to host "test-app"

  @negative @acceptance
  Scenario: Authenticate using a self signed token is denied
    When I save my place in the log file
    And I authenticate with authn-gcp using self signed token and existing account
    Then it is unauthorized
    And The following matches the log after my savepoint:
    """
    CONJ00035E Failed to decode token \(3rdPartyError ='#<JWT::DecodeError: Could not find public key for kid .*>'
    """

  @negative @acceptance
  Scenario: Authenticate using a self signed token missing 'kid' header claim is denied
    When I save my place in the log file
    And I authenticate with authn-gcp using no kid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::DecodeError: No key id (kid) found from token headers>')
    """

  @negative @acceptance
  Scenario: Authenticate using token with an invalid audience claim is denied
    Given I obtain an invalid_audience GCE identity token
    And I save my place in the log file
    When I authenticate with authn-gcp using obtained GCE token and existing account
    Then it is unauthorized
    And The following matches the log after my savepoint:
    """
    CONJ00067E 'audience' token claim .* is invalid. The format should be 'conjur/<account-name>/<host-id>'
    """

  @negative @acceptance
  Scenario: Missing GCP access token is a bad request
    Given I save my place in the log file
    When I authenticate with authn-gcp using no token and existing account
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  @negative @acceptance
  Scenario: Empty GCP access token is a bad request
    Given I save my place in the log file
    When I authenticate with authn-gcp using empty token and existing account
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  # "authn-gcp/project-id" annotation is set because at least one of the annotations is expected.
  @negative @acceptance
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
    And I set "authn-gcp/project-id" GCE annotation to host "test-app"
    And I save my place in the log file
    And I obtain a valid GCE identity token
    When I authenticate with authn-gcp using valid GCE token and existing account
    Then it is forbidden
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'host/test-app' does not have 'authenticate' privilege on cucumber:webservice:conjur/authn-gcp
    """

  @negative @acceptance
  Scenario: Authenticate using token in standard format and host with only service-account-email annotation set is denied
    Given I have host "test-app"
    And I remove all annotations from host "test-app"
    When I set "authn-gcp/service-account-email" GCE annotation to host "test-app"
    And I save my place in the log file
    And I obtain a standard_format GCE identity token
    And I authenticate with authn-gcp using obtained GCE token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00068E Claim 'service-account-email' is missing from Google's JWT token. Verify that you configured the host with permitted restrictions. In case of Compute Engine token, verify that you requested the token using 'format=full'
    """

  @negative @acceptance
  Scenario: Authenticate using token in standard format and host with only project-id annotation set is denied
    Given I have host "test-app"
    And I remove all annotations from host "test-app"
    When I set "authn-gcp/project-id" GCE annotation to host "test-app"
    And I save my place in the log file
    And I obtain a standard_format GCE identity token
    And I authenticate with authn-gcp using obtained GCE token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00068E Claim 'project-id' is missing from Google's JWT token. Verify that you configured the host with permitted restrictions. In case of Compute Engine token, verify that you requested the token using 'format=full'
    """

  @negative @acceptance
  Scenario: Authenticate using token in standard format and host with only instance-name annotation set is denied
    Given I have host "test-app"
    And I remove all annotations from host "test-app"
    When I set "authn-gcp/instance-name" GCE annotation to host "test-app"
    And I save my place in the log file
    And I obtain a standard_format GCE identity token
    And I authenticate with authn-gcp using obtained GCE token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00069E Role must have at least one of the following constraints: ["project-id", "service-account-id", "service-account-email"]
    """
