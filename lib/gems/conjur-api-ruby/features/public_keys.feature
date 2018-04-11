Feature: Fetch public keys for a user.

  Background:
    Given a new user

  Scenario: User has a uidnumber.
    When I run the code:
    """
    Conjur::API.public_keys @user.login
    """
    Then the result should be the public key
