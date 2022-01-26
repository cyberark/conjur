@authenticators_oidc
Feature: OIDC Authenticator - Performance tests

  In this feature we test that OIDC Authenticator performance is meeting
  the SLA. We run multiple authn-oidc requests in multiple threads and verify
  that the average time of a request is no more that the agreed time.
  We test both successful requests and unsuccessful requests.

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """
    And I am the super-user
    And I successfully set OIDC variables

  @performance
  Scenario: successful requests
    And I fetch an ID Token for username "alice" and password "alice"
    When I authenticate 1000 times in 10 threads via OIDC with id token
    Then The avg authentication request responds in less than 0.75 seconds

  @performance
  Scenario: Unsuccessful requests with an invalid token
    When I authenticate 1000 times in 10 threads via OIDC with invalid id token
    Then The avg authentication request responds in less than 0.75 seconds
