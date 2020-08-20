Feature: Users and Hosts can be CIDR restricted

Users and Hosts can be restricted to only allow authentication
from a particular network, defined by a CIDR in the policy

  Scenario: Loading users and hosts with CIDR restrictions

    Given I load a policy:
    """
    - !user
      id: alice
      restricted_to: 192.168.101.1

    - !user
      id: bob
      restricted_to: 192.168.0.0/16

    - !host
      id: serviceA
      restricted_to: [ 192.168.0.1, 192.168.1.10/32 ]
    """

    When I show the user "alice"
    Then the "restricted_to" should be: 
    """
      ["192.168.101.1/32"]
    """

    When I show the user "bob"
    Then the "restricted_to" should be:
    """
      ["192.168.0.0/16"]
    """ 

    When I show the host "serviceA"
    Then the "restricted_to" should be:
    """
       ["192.168.0.1/32", "192.168.1.10/32"]
    """
