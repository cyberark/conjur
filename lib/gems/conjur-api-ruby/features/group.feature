Feature: Display Group object fields.

  Background:
    Given a new group

  Scenario: Group has a gidnumber.
    Then I run the code:
    """
    @group.gidnumber
    """
    Then the result should be "1000"
