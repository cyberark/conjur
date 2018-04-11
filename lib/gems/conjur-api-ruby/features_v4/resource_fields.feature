Feature: Display basic resource fields.

  Scenario: Group exposes id, kind, identifier, and gidnumber.
    When I run the code:
    """
    resource = $conjur.resource('cucumber:group:developers')
    [ resource.id, resource.account, resource.kind, resource.identifier, resource.gidnumber ]
    """
    Then the JSON should be:
    """
    [
      "cucumber:group:developers",
      "cucumber",
      "group",
      "developers",
      2000
    ]
    """

  Scenario: User exposes id, kind, identifier, and uidnumber.
    When I run the code:
    """
    resource = $conjur.resource('cucumber:user:alice')
    [ resource.id, resource.account, resource.kind, resource.identifier, resource.uidnumber ]
    """
    Then the JSON should be:
    """
    [
      "cucumber:user:alice",
      "cucumber",
      "user",
      "alice",
      2000
    ]
    """

  Scenario: Resource#owner is the owner object
    When I run the code:
    """
    $conjur.resource('cucumber:group:developers').owner.id
    """
    Then the result should be "cucumber:group:security_admin"
    And I run the code:
    """
    $conjur.resource('cucumber:group:developers').class
    """
    Then the result should be "Conjur::Group"
