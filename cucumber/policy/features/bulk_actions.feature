@policy
Feature: YAML anchors can be used for bulk actions

  @smoke
  Scenario: Group records for bulk actions
    Sometimes you will want to grant privileges or perform actions on a group
    of roles or resources.  In this policy, two AWS-related variables (secrets)
    are grouped into an alias using a YAML anchor.  The policy grants execute
    (fetch) access on them to the layer `rundeck`. Use of the anchor keeps the
    policy shorter and easier to update. If the 'rundeck' layer needs fetch
    access to another variable, it can simply be added to the variables list.

    Given I load a policy:
    """
    - &variables
      - !variable aws_access_key_id
      - !variable aws_secret_access_key
    
    - !layer &rundeck rundeck
    
    - !permit
      role: *rundeck
      privilege: [execute]
      resource: *variables
    """
    When I list the roles permitted to execute variable "aws_access_key_id"
    Then the role list includes layer "rundeck"
    And I list the roles permitted to execute variable "aws_secret_access_key"
    Then the role list includes layer "rundeck"
