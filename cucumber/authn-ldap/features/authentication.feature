Feature: Exchange a users's valid LDAP password for a signed authentication token

  A user's LDAP password can be used to obtain a signed authentication token.

  The token is a signed JSON structure that contains the role id. The
  token can be sent as the `Authorization` header to other Possum REST
  functions as proof of authentication.

  Background:
    Given a policy:
    """
    - !user alice
    - !user bob

    - !policy
      id: conjur/authn-ldap/test
      body:
      - !webservice

      - !group clients

      - !permit
        role: !group clients
        privilege: [ read, authenticate ]
        resource: !webservice

    - !grant
      role: !group conjur/authn-ldap/test/clients
      member: !user alice
    """

  Scenario: A role's API can be used to authenticate
    Then I can POST "/authn-ldap/test/cucumber/alice/authenticate" with plain text body ":alice_api_key"

  # Scenario: Attempting to use an invalid API key to authenticate result in 401 error
  #   When I POST "/authn/cucumber/alice/authenticate" with plain text body "wrong-api-key"
  #   Then the HTTP response status code is 401
