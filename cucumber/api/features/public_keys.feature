@api
@logged-in
Feature: List a role's public keys

  Background:
    Given I create a new user "alice"
    And I create a new "public_key" resource called "user/alice/workstation"
    And I create a new "public_key" resource called "user/alice/laptop"

  @smoke
  Scenario: Public keys can be added and queried through the REST API.

    Adding a public key for a role requires `update` privilege on the `public_key` resource.

    Listing the public keys of a role doesn't require authentication.

    Given I POST "/secrets/cucumber/public_key/user/alice/workstation" with body:
    """
    ssh-rsa AAAAB3NzagKagJ+JTg2LzKz3WzEe49HhIqxF workstation
    """
    And   I POST "/secrets/cucumber/public_key/user/alice/laptop" with body:
    """
    ssh-rsa AAAAB3NzagKagJ+JTg2LzKz3WzEe49HhIqxF laptop
    """
    And  I log out
    When I GET "/public_keys/cucumber/user/alice"
    Then the text result is:
    """
    ssh-rsa AAAAB3NzagKagJ+JTg2LzKz3WzEe49HhIqxF laptop
    ssh-rsa AAAAB3NzagKagJ+JTg2LzKz3WzEe49HhIqxF workstation
    
    """
