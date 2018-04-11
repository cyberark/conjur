Feature: Enumerate roles which have a permission on a resource.

  Scenario: Permitted roles can be enumerated.
    When I run the code:
    """
    $conjur.resource('cucumber:variable:db-password').permitted_roles 'execute'
    """
    Then the JSON should include "cucumber:layer:myapp"
