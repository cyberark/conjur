Feature: Display basic resource fields.

  Background:
    Given I run the code:
    """
    $conjur.load_policy 'root', <<-POLICY
    - !group
      id: developers
      annotations:
        gidnumber: 2000
    POLICY
    """

  Scenario: Resource exposes id, kind, identifier, and attributes.
    When I run the code:
    """
    resource = $conjur.resource('cucumber:group:developers')
    [ resource.id, resource.account, resource.kind, resource.identifier, resource.attributes ]
    """
    Then the JSON should be:
    """
    [
      "cucumber:group:developers",
      "cucumber",
      "group",
      "developers",
      {
        "annotations": [
          {
            "name": "gidnumber",
            "policy": "cucumber:policy:root",
            "value": "2000"
          }
        ],
        "owner": "cucumber:user:admin",
        "permissions": [
        ],
        "policy": "cucumber:policy:root"
      }
    ]
    """

  Scenario: Resource#owner is the owner object
    When I run the code:
    """
    $conjur.resource('cucumber:group:developers').owner.id
    """
    Then the result should be "cucumber:user:admin"
    And I run the code:
    """
    $conjur.resource('cucumber:group:developers').class
    """
    Then the result should be "Conjur::Group"
