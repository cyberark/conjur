Feature: Authenticator configuration

  Background:
    Given I have user "no-authn-access"
    And I have user "authn-reader"
    And I have user "authn-writer"
    And a policy:
    """
    - !policy
      id: conjur/authn-ldap/test
      body:
      - !webservice

      - !group readers

      - !permit
        role: !group readers
        privileges: [ read ]
        resource: !webservice

      - !group writers

      - !permit
        role: !group writers
        privileges: [ update ]
        resource: !webservice

    - !grant
      role: !group conjur/authn-ldap/test/readers
      member: !user authn-reader

    - !grant
      role: !group conjur/authn-ldap/test/writers
      member: !user authn-writer
    """

  Scenario: Authenticator is configured
    When I login as "authn-writer"
    And I successfully PATCH "/authn-ldap/test/cucumber" with body:
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

  Scenario: Authenticator does not exist
    When I am the super-user
    And I PATCH "/authn-ldap/test/nope" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 404

  Scenario: Authenticated user can not read authenticator
    When I login as "no-authn-access"
    And I PATCH "/authn-ldap/test/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 404

  Scenario: Authenticated user can not write authenticator
    When I login as "authn-reader"
    And I PATCH "/authn-ldap/test/cucumber" with body:
    """
    enabled=true
    """
    Then the HTTP response status code is 403
