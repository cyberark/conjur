Feature: Rotate the API key of a role

  The API key of a role can be automatically changed ("rotated") to a new random string.

  A role can rotate its own API key using the password or current API key. A role can also
  rotate the API key of another role if it has `update` privilege on the role.

  In these test cases, API key rotation is performed against Bob.
  API key rotation is executed by 5 roles:
    - Bob himself
    - a user with update permission, "privileged_user"
    - a user without update permission, "unprivileged_user"
    - a host belonging to a layer with update permission, "privileged_host"
    - a host without update permission, "unprivileged_host"
  These roles attempt to rotate Bob's API key with all authentication methods
  available to them.

  The host with update permission will also attempt to rotate his own key,
  to validate behavior for each authentication method.

  Background:
    Given I create a new user "bob"
    And I create a new user "privileged_user"
    And I create a new user "unprivileged_user"
    And I have host "privileged_host"
    And I have host "unprivileged_host"
    And I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user bob
    - !user privileged_user
    - !layer host_layer
    - !host privileged_host

    # give privileged_user update permissions over user bob
    - !permit
      role: !user privileged_user
      privilege: [ update ]
      resource: !user bob

    # assign privileged_host as a member of host_layer
    - !grant
      role: !layer host_layer
      member: !host privileged_host

    # give host_layer,
    # and by extension privileged_host,
    # update permissions over bob
    - !permit
      role: !layer host_layer
      privilege: [ update ]
      resource: !user bob
    """
    And I log out

  # Bob rotating his own API key

  Scenario: Bob's password CAN be used to rotate own API key
    Given I set the password for "bob" to "My-Password1"
    When I can PUT "/authn/cucumber/api_key?role=user:bob" with username "bob" and password "My-Password1"
    Then the HTTP response status code is 200
    And the result is the API key for user "bob"

  Scenario: Bob's API key CAN be used to rotate own API key
    When I can PUT "/authn/cucumber/api_key" with username "bob" and password ":cucumber:user:bob_api_key"
    Then the HTTP response status code is 200
    And the result is the API key for user "bob"

  Scenario: Bob's access token CAN NOT be used to rotate own API key
    Given I login as "bob"
    When I PUT "/authn/cucumber/api_key"
    Then the HTTP response status code is 401

  Scenario: Bob's access token CAN NOT be used to rotate own API key using role parameter with self role value
    Given I login as "bob"
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 401

  # A user without update permission rotating Bob's API key

  Scenario: User without permissions CAN NOT rotate Bob's API key using their own API key
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "unprivileged_user" and password ":cucumber:user:unprivileged_user_api_key"
    Then the HTTP response status code is 401

  Scenario: User without permissions CAN NOT rotate Bob's API key using their password
    Given I set the password for "unprivileged_user" to "Passw0rd-Unprivileged"
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "unprivileged_user" and password "Passw0rd-Unprivileged"
    Then the HTTP response status code is 401

  Scenario: User without permissions CAN NOT rotate Bob's API key using an access token
    Given I login as "unprivileged_user"
    When I PUT "/authn/cucumber/api_key?role=user:carl"
    Then the HTTP response status code is 401

  # A user with update permission rotating Bob's API key

  Scenario: A User with update privilege CAN rotate Bob's API key using an access token
    Given I login as "privileged_user"
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 200
    And the result is the API key for user "bob"

  Scenario: A User with update privilege CAN NOT rotate another user's API key using their own API key
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "privileged_user" and password ":cucumber:user:privileged_user_api_key"
    Then the HTTP response status code is 401

  Scenario: A User with update privilege CAN NOT rotate another user's API key using their password
    Given I set the password for "privileged_user" to "Passw0rd-Privileged"
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "privileged_user" and password "Passw0rd-Privileged"
    Then the HTTP response status code is 401

  # A host rotating their own API key

  Scenario: A Host CAN rotate their own API key using their API key
    When I PUT "/authn/cucumber/api_key?role=host:privileged_host" with username "host/privileged_host" and password ":cucumber:host:privileged_host_api_key"
    Then the HTTP response status code is 200
    And the result is the API key for host "privileged_host"

  Scenario: A Host CAN NOT rotate their own API key using an access token
    Given I login as "host/privileged_host"
    When I PUT "/authn/cucumber/api_key"
    Then the HTTP response status code is 401

  Scenario: A Host CAN NOT rotate their own API key using an access token and a role parameter with self role value
    Given I login as "host/privileged_host"
    When I PUT "/authn/cucumber/api_key?role=host:privileged_host"
    Then the HTTP response status code is 401

  # A host with update permission rotating Bob's API key

  Scenario: A Host with update privilege CAN rotate Bob's API key with an access token
    Given I login as "host/privileged_host"
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 200
    And the result is the API key for user "bob"

  Scenario: A Host with update privilege CAN NOT rotate Bob's API key with their own API key
    When I PUT "/authn/cucumber/api_key?role=user:carl" with username "host/host1" and password ":cucucmber:host:host1_api_key"
    Then the HTTP response status code is 401

  # A host without update permission rotating Bob's API key

  Scenario: A Host without update privilege CAN NOT rotate Bob's API key with an access token
    Given I login as "host/unprivileged_host"
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 401

  Scenario: A Host without update privilege CAN NOT rotate a user's API key with their own API key
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "host/unprivileged_host" and password ":cucumber:host:unprivileged_host_api_key"
    Then the HTTP response status code is 401
