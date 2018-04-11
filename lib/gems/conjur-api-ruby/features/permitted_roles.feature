Feature: Enumerate roles which have a permission on a resource.

  Background:
    Given I run the code:
    """
    $conjur.load_policy 'root', <<-POLICY
    - !variable db-password

    - !layer myapp

    - !permit
      role: !layer myapp
      privilege: execute
      resource: !variable db-password
    POLICY
    """

  @wip
  Scenario: Permitted roles can be enumerated.
    When I run the code:
    """
    $conjur.resource('cucumber:variable:db-password').permitted_roles 'execute'
    """
    Then the JSON should be:
    """
    [
      "cucumber:layer:myapp",
      "cucumber:user:admin"
    ]
    """
