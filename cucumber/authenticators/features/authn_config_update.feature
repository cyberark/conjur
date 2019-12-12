Feature: Authenticator can be enabled

  Background:
    Given a policy:
    """
    - !policy
      id: conjur/authn-ldap/test
      body:
      - !webservice
    """
    And I am the super-user

  Scenario:
    When I successfully PATCH "/authn-ldap/test/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 204
    And authenticator "cucumber:webservice:conjur/authn-ldap/test" is enabled

    When I successfully PATCH "/authn-ldap/test/cucumber" with body:
    """
    enabled=false
    """
    Then the HTTP response status code is 204
    And authenticator "cucumber:webservice:conjur/authn-ldap/test" is disabled
