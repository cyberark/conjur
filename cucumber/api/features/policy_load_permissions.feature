Feature: Updating policies

  `create` privilege is sufficient to add records to a policy via POST.

  Policy updates can be performed in any of three modes: PUT, PATCH, and POST.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/:account/policy/bootstrap" with body:
    """
    - !policy
      id: @namespace@
      body:
      - !user alice
      - !user bob
      - !user carol

      - !policy
        id: dev
        owner: !user alice
        body:
        - !policy
          id: db

      - !permit
        resource: !policy dev/db
        privilege: [ create, update ]
        role: !user bob

      - !permit
        resource: !policy dev/db
        privilege: [ create ]
        role: !user carol
    """
    And I login as "alice"
    And I successfully POST "/policies/:account/policy/:namespace/dev/db" with body:
    """
    - !variable a
    """
