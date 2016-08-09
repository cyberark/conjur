@logged-in
Feature: Fetching public keys.

  Background:
    Given a new user "alice"
    And I create a new "public_key" resource called "user/alice@:user_namespace/workstation"
    And I create a new "public_key" resource called "user/alice@:user_namespace/laptop"

  Scenario: When I create a new resource has no secrets, fetching the secret results in a 404 error.
    Given I POST "/secrets/:account/public_key/user/alice@:user_namespace/workstation" with body:
    """
    ssh-rsa AAAAB3NzagKagJ+JTg2LzKz3WzEe49HhIqxF workstation
    """
    And   I POST "/secrets/:account/public_key/user/alice@:user_namespace/laptop" with body:
    """
    ssh-rsa AAAAB3NzagKagJ+JTg2LzKz3WzEe49HhIqxF laptop
    """
    And  I log out
    When I GET "/public_keys/:account/user/alice@:user_namespace"
    Then the text result is:
    """
    ssh-rsa AAAAB3NzagKagJ+JTg2LzKz3WzEe49HhIqxF laptop
    ssh-rsa AAAAB3NzagKagJ+JTg2LzKz3WzEe49HhIqxF workstation
    
    """
