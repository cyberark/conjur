@api
Feature: Rotate the API key of a role

  The API key of a role can be automatically changed ("rotated") to a new random string.

  A role can rotate its own API key using the password or current API key. A role can also
  rotate the API key of another role if it has `update` privilege on the role.

  In these test cases, API key rotation is performed against Bob.
  API key rotation is executed by 5 roles:
    - Bob himself
    - a user with update permission, "privileged_user"
    - a user without update permission, "unprivileged_user"
    - a host with no api key, "privileged_host_without_apikey"
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
    And I have host "privileged_host_without_apikey" without api key
    And I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: p1
      body:
        - !layer hidden_layer

    - !user bob
    - !user privileged_user
    - !user read_only_privileged_user
    - !user not_privileged_user
    - !layer host_layer
    - !policy strict_policy
    - !group super_users
    - !host privileged_host
    - !host privileged_host_without_apikey

    # give privileged_user update permissions over user bob
    - !permit
      role: !user privileged_user
      privilege: [ update ]
      resource: !user bob

    # give privileged_user update permissions over layer host_layer
    - !permit
      role: !user privileged_user
      privilege: [ update ]
      resource: !layer host_layer
      
    # give privileged_user update permissions over policy strict_policy
    - !permit
      role: !user privileged_user
      privilege: [ update ]
      resource: !policy strict_policy

    # give privileged_user update permissions over group super_users
    - !permit
      role: !user privileged_user
      privilege: [ update ]
      resource: !group super_users
          
    # give read_only_privileged_user read permissions over host_layer
    - !permit
      role: !user read_only_privileged_user
      privilege: [ read ]
      resource: !layer host_layer

    # give read_only_privileged_user read permissions over user bob
    - !permit
      role: !user read_only_privileged_user
      privilege: [ read ]
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

    #give update permission to a host without api key
    - !permit
      role: !host privileged_host
      privilege: [ update ]
      resource: !host privileged_host_without_apikey
    """
    And I log out

  # Bob rotating his own API key
  @smoke
  Scenario: Bob's password CAN be used to rotate own API key
    Given I set the password for "bob" to "My-Password1"
    And I save my place in the audit log file
    When I can PUT "/authn/cucumber/api_key?role=user:bob" with username "bob" and password "My-Password1"
    Then the HTTP response status code is 200
    And the result is the API key for user "bob"
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:bob successfully rotated their API key
    """

  @smoke
  Scenario: Bob's API key CAN be used to rotate own API key
    Given I save my place in the audit log file
    When I can PUT "/authn/cucumber/api_key" with username "bob" and password ":cucumber:user:bob_api_key"
    Then the HTTP response status code is 200
    And the result is the API key for user "bob"
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:bob successfully rotated their API key
    """

  @negative @acceptance
  Scenario: Bob's access token CANNOT be used to rotate own API key
    Given I login as "bob"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Credential strength is insufficient
    """

  @negative @acceptance
  Scenario: Bob's access token CANNOT be used to rotate own API key using role parameter with self role value
    Given I login as "bob"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Credential strength is insufficient
    """


  # A user without update permission rotating Bob's API key
  @negative @acceptance
  Scenario: User without permissions CANNOT rotate Bob's API key using their own API key
    Given I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "unprivileged_user" and password ":cucumber:user:unprivileged_user_api_key"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Operation attempted against foreign user
    """

  @negative @acceptance
  Scenario: User without permissions CANNOT rotate Bob's API key using their password
    Given I set the password for "unprivileged_user" to "Passw0rd-Unprivileged"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "unprivileged_user" and password "Passw0rd-Unprivileged"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Operation attempted against foreign user
    """

   # A user with update permission rotating layer API key
  @negative @acceptance
  Scenario: A User with update privilege CANNOT rotate an API key of a non actor Role resource (user/host)
    Given I login as "privileged_user"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=layer:host_layer"
    Then the HTTP response status code is 405
    And The following appears in the audit log after my savepoint:
    """
    CONJ00120E Role 'cucumber:layer:host_layer' has no credentials
    """
    And The following appears in the audit log after my savepoint:
    """
    CONJ00126E Role 'cucumber:layer:host_layer' is not applicable for key rotation
    """

   # A user with update permission rotating policy API key
  @negative @acceptance
  Scenario: A User with update privilege CANNOT rotate an API key of a non actor Role resource (user/host)
    Given I login as "privileged_user"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=policy:strict_policy"
    Then the HTTP response status code is 405
    And The following appears in the audit log after my savepoint:
    """
    CONJ00120E Role 'cucumber:policy:strict_policy' has no credentials
    """
    And The following appears in the audit log after my savepoint:
    """
    CONJ00126E Role 'cucumber:policy:strict_policy' is not applicable for key rotation
    """

   # A user with update permission rotating group API key
  @negative @acceptance
  Scenario: A User with update privilege CANNOT rotate an API key of a non actor Role resource (user/host)
    Given I login as "privileged_user"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=group:super_users"
    Then the HTTP response status code is 405
    And The following appears in the audit log after my savepoint:
    """
    CONJ00120E Role 'cucumber:group:super_users' has no credentials
    """
    And The following appears in the audit log after my savepoint:
    """
    CONJ00126E Role 'cucumber:group:super_users' is not applicable for key rotation
    """

  # A user with read permission rotating layer API key
  @negative @acceptance
  Scenario: A User with read ONLY privilege CANNOT rotate an API key of a non actor Role resource (user/host)
    Given I login as "read_only_privileged_user"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=layer:host_layer"
    Then the HTTP response status code is 403
    And The following appears in the audit log after my savepoint:
    """
    CONJ00122E Role 'cucumber:user:read_only_privileged_user' does not have permissions to access the requested resource
    """

  # A user with read permission rotating bob's API key
  @negative @acceptance
  Scenario: A User with read ONLY privilege CANNOT rotate an API key of a non actor Role resource (user/host)
    Given I login as "read_only_privileged_user"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 403
    And The following appears in the audit log after my savepoint:
    """
    CONJ00124E Role 'cucumber:user:read_only_privileged_user' has insufficient privileges over the resource
    """

  @negative @acceptance
  Scenario: A User with tries to rotate an API key of a non existent Role resource
    Given I login as "privileged_user"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:does_not_exist"
    Then the HTTP response status code is 404
    And The following appears in the audit log after my savepoint:
    """
    CONJ00123E Resource 'user:does_not_exist' requested by role 'cucumber:user:privileged_user' not found
    """

  # A user with read permission rotating layer API key not visible to him
  @negative @acceptance
  Scenario: A User with NO privilege CANNOT rotate an API key of a non actor Role resource (user/host)
    Given I login as "not_privileged_user"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=layer:p1/hidden_layer"
    Then the HTTP response status code is 404
    And The following appears in the audit log after my savepoint:
    """
    CONJ00125E The requested resource 'cucumber:layer:p1/hidden_layer' is not visible to Role 'cucumber:user:not_privileged_user'
    """
    And The following appears in the audit log after my savepoint:
    """
    CONJ00123E Resource 'cucumber:layer:p1/hidden_layer' requested by role 'cucumber:user:not_privileged_user' not found
    """

  # A user with update permission rotating Bob's API key
  @smoke
  Scenario: A User with update privilege CAN rotate Bob's API key using an access token
    Given I login as "privileged_user"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 200
    And the result is the API key for user "bob"
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:privileged_user successfully rotated the api key for cucumber:user:bob
    """

  @negative @acceptance
  Scenario: A User with update privilege CANNOT rotate another user's API key using their own API key
    Given I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "privileged_user" and password ":cucumber:user:privileged_user_api_key"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Operation attempted against foreign user
    """

  @negative @acceptance
  Scenario: A User with update privilege CANNOT rotate another user's API key using their password
    Given I set the password for "privileged_user" to "Passw0rd-Privileged"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "privileged_user" and password "Passw0rd-Privileged"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Operation attempted against foreign user
    """

  # A host rotating their own API key
  @smoke
  Scenario: A Host CAN rotate their own API key using their API key
    Given I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=host:privileged_host" with username "host/privileged_host" and password ":cucumber:host:privileged_host_api_key"
    Then the HTTP response status code is 200
    And the result is the API key for host "privileged_host"
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:privileged_host successfully rotated their API key
    """

  @negative @acceptance
  Scenario: A Host without api key CANNOT rotate their own API key
    Given I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=host:privileged_host_without_apikey" with username "host/privileged_host_without_apikey" and password ":cucumber:host:api_key"
    Then the HTTP response status code is 401

  @negative @acceptance
  Scenario: A Host CANNOT rotate their own API key using an access token
    Given I login as "host/privileged_host"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Credential strength is insufficient
    """

  @negative @acceptance
  Scenario: A Host CANNOT rotate their own API key using an access token and a role parameter with self role value
    Given I login as "host/privileged_host"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=host:privileged_host"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Credential strength is insufficient
    """

  # A host with update permission rotating Bob's API key
  @smoke
  Scenario: A Host with update privilege CAN rotate Bob's API key with an access token
    Given I login as "host/privileged_host"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 200
    And the result is the API key for user "bob"
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:privileged_host successfully rotated the api key for cucumber:user:bob
    """

   # A host with update permission rotating host without api key
  @negative @acceptance
  Scenario: A Host with update privilege CANNOT rotate host API key that doesn't have api key
    Given I login as "host/privileged_host"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=host:privileged_host_without_apikey"
    Then the HTTP response status code is 405
    And The following appears in the audit log after my savepoint:
    """
    Operation is not supported for host since it does not use api-key for authentication
    """

  @negative @acceptance
  Scenario: A Host with update privilege CANNOT rotate Bob's API key with their own API key
    Given I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "host/privileged_host" and password ":cucumber:host:privileged_host_api_key"
    Then the HTTP response status code is 401
    And The following appears in the audit log after my savepoint:
    """
    Operation attempted against foreign user
    """

  # A host without update permission rotating Bob's API key
  @negative @acceptance
  Scenario: A Host without update privilege CANNOT rotate Bob's API key with an access token
    Given I login as "host/unprivileged_host"
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: A Host without update privilege CANNOT rotate a user's API key with their own API key
    When I PUT "/authn/cucumber/api_key?role=user:bob" with username "host/unprivileged_host" and password ":cucumber:host:unprivileged_host_api_key"
    Then the HTTP response status code is 401

  # Test rotation against nonexistent user
  @negative @acceptance
  Scenario: Bob CANNOT rotate a nonexistent user's API key using basic auth and an API key, RESULTS IN 401
    Given I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:does_not_exist" with username "bob" and password ":cucumber:user:bob_api_key"
    Then the HTTP response status code is 404
    And The following appears in the audit log after my savepoint:
    """
    CONJ00123E Resource 'user:does_not_exist' requested by role 'cucumber:user:bob' not found
    """

  @negative @acceptance
  Scenario: Bob CANNOT rotate a nonexistent user's API key using basic auth and a password, RESULTS IN 401
    Given I set the password for "bob" to "Passw0rd-Bob"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:does_not_exist" with username "bob" and password "Passw0rd-Bob"
    Then the HTTP response status code is 404
    And The following appears in the audit log after my savepoint:
    """
    CONJ00123E Resource 'user:does_not_exist' requested by role 'cucumber:user:bob' not found
    """

  @negative @acceptance
  Scenario: Bob CANNOT rotate a nonexistent user's API key using an access token, RESULTS IN 401
    Given I login as "bob"
    And I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=user:does_not_exist"
    Then the HTTP response status code is 404
    And The following appears in the audit log after my savepoint:
    """
    CONJ00123E Resource 'user:does_not_exist' requested by role 'cucumber:user:bob' not found
    """

  @negative @acceptance
  Scenario: Bob CANNOT rotate API key for user in nonexistent account, RESULTS IN 401
    Given I save my place in the audit log file
    When I PUT "/authn/cucumber/api_key?role=nonexistent_account:user:bob" with username "bob" and password ":cucumber:user:bob_api_key"
    Then the HTTP response status code is 404
    And The following appears in the audit log after my savepoint:
    """
    CONJ00123E Resource 'nonexistent_account:user:bob' requested by role 'cucumber:user:bob' not found
    """
