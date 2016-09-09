Feature: Updating policies

  The initial policy is loaded using the `possum` command line tool, typically running as a one-off container
  command inside the container itself.

  The initial policy create sub-policies which can be modified by privileged users.

  Background:
    Given I am the super-user
    And I successfully POST "/policies/:account/policy/bootstrap" with body:
    """
    - !user alice
    - !user bob
    - !user charles

    - !policy
      id: dev
      owner: !user alice
      body:
      - !policy
        id: db
        body: []

    - !permit
      resource: !policy dev/db
      privilege: [ execute ]
      role: !user bob
    """

  Scenario: A role with "execute" privilege can update a policy.
    When I login as "bob"
    Then I successfully POST "/policies/:account/policy/dev/db" with body:
    """
    - !layer
    """
    And I successfully GET "/resources/:account/layer/dev/db"

  Scenario: A role without "execute" privilege cannot update a policy.
    When I login as "charles"
    When I POST "/policies/:account/policy/dev/db" with body:
    """
    - !layer
    """
    Then it's forbidden
