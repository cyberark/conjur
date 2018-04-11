Feature: Display User object fields.

  Background:
    Given a new user

  Scenario: User has a uidnumber.
    Then I run the code:
    """
    @user.uidnumber
    """
    Then the result should be "1000"

  Scenario: Logged-in user is the current_role.
    Then I run the code:
    """
    expect($conjur.current_role(Conjur.configuration.account).id.to_s).to eq("cucumber:user:admin")
    """
