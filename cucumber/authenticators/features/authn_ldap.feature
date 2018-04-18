Feature: Users can login with LDAP credentials from an authorized LDAP server

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

  Scenario: An LDAP user authorized in Conjur can login
    When I send an LDAP login for authorized Conjur user "alice"
    Then I get back a valid login token for "alice"

#   @logged-in
#   Scenario: Bearer token cannot be used to login

#     The login method requires the password; login cannot be performed using the auth token
#     as a credential.

#     When I GET "/authn/cucumber/login"
#     Then the HTTP response status code is 401

#   @logged-in-admin
#   Scenario: "Super" users cannot login as other users

#     Users can never login as other users.

#     When I GET "/authn/cucumber/login?role=user:alice"
#     Then the HTTP response status code is 401
